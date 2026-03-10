#!/usr/bin/env python3
"""
fmetrics-predict.py — k-NN regression for fsuite runtime prediction.

Pure stdlib (no numpy/scipy needed). Queries historical telemetry from SQLite,
normalizes features, finds k nearest neighbors, and predicts runtime.

Usage:
    python3 fmetrics-predict.py --db ~/.fsuite/telemetry.db \
        --items 500 --bytes 10000000 --depth 3 --output json
"""

import argparse
import json
import math
import sqlite3
import statistics
import sys
from contextlib import closing
from typing import Dict, List, Optional, Tuple

VERSION = "2.1.0"
DEFAULT_K = 5
MIN_SAMPLES = 5
FTREE_MODES = ("tree", "recon", "snapshot")


def connect_db(db_path: str) -> sqlite3.Connection:
    """Connect to the telemetry database."""
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def get_tool_data(
    conn: sqlite3.Connection,
    tool: str,
    mode: Optional[str] = None,
    require_bytes: bool = True,
) -> List[dict]:
    """Fetch successful historical runs for a given tool.

    If require_bytes is True, only returns rows with bytes_scanned >= 0.
    If False, returns all rows with items_scanned >= 0, substituting 0 for negative bytes.
    """
    where = [
        "tool = ?",
        "exit_code = 0",
        "items_scanned >= 0",
    ]
    params: List[object] = [tool]

    if mode:
        where.append("mode = ?")
        params.append(mode)

    if require_bytes:
        where.append("bytes_scanned >= 0")

    cursor = conn.execute(
        "SELECT duration_ms, items_scanned, bytes_scanned, depth, mode "
        f"FROM telemetry WHERE {' AND '.join(where)}",
        tuple(params),
    )
    rows = [dict(row) for row in cursor.fetchall()]
    # If not requiring bytes, substitute 0 for negative values
    if not require_bytes:
        for row in rows:
            if row["bytes_scanned"] < 0:
                row["bytes_scanned"] = 0
    return rows


def compute_stats(values: List[float]) -> Tuple[float, float]:
    """Compute mean and std deviation."""
    if not values:
        return 0.0, 0.0
    n = len(values)
    mean = sum(values) / n
    if n < 2:
        return mean, 0.0
    variance = sum((x - mean) ** 2 for x in values) / (n - 1)
    return mean, math.sqrt(variance)


def normalized_feature_delta(target: float, point: float, mean: float, std: float) -> float:
    """Measure distance for one feature, handling zero-spread datasets honestly."""
    if std == 0:
        return 0.0 if target == point else 4.0
    return abs(target - point) / std


def euclidean_distance(a: List[float], b: List[float]) -> float:
    """Compute Euclidean distance between two feature vectors."""
    if len(a) != len(b):
        raise ValueError(f"Vector lengths must match: {len(a)} != {len(b)}")
    return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))


def filter_outliers_iqr(data: List[dict], factor: float = 1.5) -> List[dict]:
    """Remove duration outliers using IQR method."""
    if len(data) < 4:
        return data
    durations = sorted(d["duration_ms"] for d in data)
    quartiles = statistics.quantiles(durations, n=4)
    q1, q3 = quartiles[0], quartiles[2]
    iqr = q3 - q1
    lower = q1 - factor * iqr
    upper = q3 + factor * iqr
    return [d for d in data if lower <= d["duration_ms"] <= upper]


def predict_for_tool(
    data: List[dict],
    target_items: int,
    target_bytes: int,
    target_depth: int,
    k: int = DEFAULT_K,
) -> Optional[dict]:
    """
    k-NN regression prediction for a single tool.

    Features: items_scanned, bytes_scanned, depth
    Target: duration_ms
    """
    if len(data) < MIN_SAMPLES:
        return None

    # Remove outliers before prediction
    data = filter_outliers_iqr(data)
    if len(data) < MIN_SAMPLES:
        return None

    # Extract feature columns
    items_vals = [float(d["items_scanned"]) for d in data]
    bytes_vals = [float(d["bytes_scanned"]) for d in data]
    depth_vals = [float(d["depth"]) for d in data]
    durations = [float(d["duration_ms"]) for d in data]

    # Compute normalization stats
    items_mean, items_std = compute_stats(items_vals)
    bytes_mean, bytes_std = compute_stats(bytes_vals)
    depth_mean, depth_std = compute_stats(depth_vals)

    # Compute distances for all historical points
    distances = []
    for i, d in enumerate(data):
        dist = math.sqrt(sum(
            component ** 2 for component in [
                normalized_feature_delta(float(target_items), items_vals[i], items_mean, items_std),
                normalized_feature_delta(float(target_bytes), bytes_vals[i], bytes_mean, bytes_std),
                normalized_feature_delta(float(target_depth), depth_vals[i], depth_mean, depth_std),
            ]
        ))
        distances.append((dist, durations[i]))

    # Sort by distance, take k nearest
    distances.sort(key=lambda x: x[0])
    neighbors = distances[:k]

    if not neighbors:
        return None

    # Weighted average (inverse distance weighting)
    neighbor_durations = [d for _, d in neighbors]
    neighbor_distances = [dist for dist, _ in neighbors]

    # Inverse distance weighting with epsilon to prevent division by zero
    EPSILON = 1e-9
    weights = [1.0 / (d + EPSILON) for d in neighbor_distances]
    total_weight = sum(weights)
    predicted_ms = sum(w * d for w, d in zip(weights, neighbor_durations)) / total_weight

    # Confidence based on std dev of neighbors and distance spread
    pred_mean, pred_std = compute_stats(neighbor_durations)
    avg_dist = sum(neighbor_distances) / len(neighbor_distances)

    zero_spread_mismatch = any([
        items_std == 0 and float(target_items) != items_mean,
        bytes_std == 0 and float(target_bytes) != bytes_mean,
        depth_std == 0 and float(target_depth) != depth_mean,
    ])

    # Confidence heuristic: never go "high" if the feature space collapsed.
    if zero_spread_mismatch:
        confidence = "low"
    elif pred_std < pred_mean * 0.15 and avg_dist < 0.75 and len(data) >= max(k + 1, 6):
        confidence = "high"
    elif pred_std < pred_mean * 0.35 and avg_dist < 1.5:
        confidence = "medium"
    else:
        confidence = "low"

    return {
        "tool": "",  # filled by caller
        "predicted_ms": int(round(predicted_ms)),
        "std_dev_ms": int(round(pred_std)),
        "confidence": confidence,
        "k_used": len(neighbors),
        "avg_neighbor_distance": round(avg_dist, 3),
        "neighbor_durations": [int(d) for d in neighbor_durations],
        "zero_spread_mismatch": zero_spread_mismatch,
    }


def prediction_targets(tool: Optional[str], mode: Optional[str]) -> List[Tuple[str, Optional[str]]]:
    """Expand requested tool/mode into concrete prediction groups."""
    if tool == "ftree":
        if mode:
            return [("ftree", mode)]
        return [("ftree", ftree_mode) for ftree_mode in FTREE_MODES]
    if tool:
        return [(tool, None)]
    return [("ftree", ftree_mode) for ftree_mode in FTREE_MODES] + [("fsearch", None), ("fcontent", None)]


def collapse_ftree_predictions(
    predictions: List[dict],
    requested_tool: Optional[str],
    requested_mode: Optional[str],
) -> List[dict]:
    """Preserve one-row-per-tool output by collapsing default ftree predictions."""
    if requested_mode:
        return predictions

    ftree_predictions = [
        pred for pred in predictions
        if pred.get("tool") == "ftree" and pred.get("mode") in FTREE_MODES
    ]
    if not ftree_predictions:
        return predictions

    other_predictions = [
        pred for pred in predictions
        if not (pred.get("tool") == "ftree" and pred.get("mode") in FTREE_MODES)
    ]

    by_mode = {}
    total_mode_samples = 0
    for pred in ftree_predictions:
        mode_name = pred["mode"]
        by_mode[mode_name] = {
            key: value
            for key, value in pred.items()
            if key not in {"tool", "mode"}
        }
        total_mode_samples += int(pred.get("samples", 0))

    aggregate = {
        "tool": "ftree",
        "mode": "mixed",
        "predicted_ms": -1,
        "confidence": "low",
        "samples": total_mode_samples,
        "advisory": True,
        "error": "mixed ftree modes; use --mode for actionable predictions",
        "by_mode": by_mode,
    }

    if requested_tool == "ftree":
        return [aggregate]
    return [aggregate] + other_predictions


def main():
    parser = argparse.ArgumentParser(description="k-NN runtime prediction for fsuite tools")
    parser.add_argument("--db", required=True, help="Path to telemetry.db")
    parser.add_argument("--items", type=int, required=True, help="Target items_scanned")
    parser.add_argument("--bytes", type=int, default=-1, help="Target bytes_scanned")
    parser.add_argument("--depth", type=int, default=3, help="Target depth")
    parser.add_argument("--k", type=int, default=DEFAULT_K, help="Number of neighbors")
    parser.add_argument("--tool", choices=["ftree", "fsearch", "fcontent"], default=None,
                        help="Predict for specific tool only")
    parser.add_argument("--mode", choices=list(FTREE_MODES), default=None,
                        help="Restrict ftree predictions to one mode")
    parser.add_argument("--output", choices=["json", "pretty"], default="json")
    parser.add_argument("--version", action="version", version=f"fmetrics-predict {VERSION}")
    args = parser.parse_args()

    if args.k <= 0:
        parser.error("--k must be greater than 0")
    if args.mode and args.tool != "ftree":
        parser.error("--mode requires --tool ftree")

    try:
        with closing(connect_db(args.db)) as conn:
            total_samples = conn.execute(
                "SELECT COUNT(*) FROM telemetry WHERE exit_code=0"
            ).fetchone()[0]

            predictions = []

            for tool, mode in prediction_targets(args.tool, args.mode):
                # Try strict mode first (require bytes_scanned >= 0)
                data = get_tool_data(conn, tool, mode=mode, require_bytes=True)
                result = predict_for_tool(data, args.items, args.bytes, args.depth, args.k)

                # Fallback: if not enough data, try without bytes requirement
                if result is None and len(data) < MIN_SAMPLES:
                    data = get_tool_data(conn, tool, mode=mode, require_bytes=False)
                    result = predict_for_tool(data, args.items, args.bytes, args.depth, args.k)

                if result:
                    result["tool"] = tool
                    if mode:
                        result["mode"] = mode
                    result["samples"] = len(data)
                    predictions.append(result)
                else:
                    failure = {
                        "tool": tool,
                        "predicted_ms": -1,
                        "confidence": "none",
                        "samples": len(data),
                        "error": f"insufficient data, need {MIN_SAMPLES} samples, have {len(data)}",
                    }
                    if mode:
                        failure["mode"] = mode
                    predictions.append(failure)

            output = {
                "tool": "fmetrics",
                "version": VERSION,
                "subcommand": "predict",
                "method": "knn_regression",
                "k": args.k,
                "target_features": {
                    "items": args.items,
                    "bytes": args.bytes,
                    "depth": args.depth,
                },
                "requested_mode": args.mode,
                "predictions": collapse_ftree_predictions(predictions, args.tool, args.mode),
                "total_historical_samples": total_samples,
            }
    except (OSError, sqlite3.Error) as e:
        print(json.dumps({"error": f"Cannot open database: {e}"}))
        sys.exit(1)

    if args.output == "json":
        print(json.dumps(output))
    else:
        print(f"fmetrics predict -- k-NN Regression (k={args.k})")
        print("=" * 44)
        print(f"  Target: {args.items} items, {args.bytes} bytes, depth {args.depth}")
        print(f"  Historical samples: {total_samples}")
        print()
        for p in predictions:
            label = p["tool"] if not p.get("mode") else f'{p["tool"]}:{p["mode"]}'
            if p.get("predicted_ms", -1) >= 0:
                print(f"  {label:<20} ~{p['predicted_ms']}ms "
                      f"+/-{p.get('std_dev_ms', 0)}ms  "
                      f"[{p['confidence']}] ({p['samples']} samples)")
            else:
                print(f"  {label:<20} -- {p.get('error', 'no prediction')}")


if __name__ == "__main__":
    main()
