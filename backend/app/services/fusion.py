from collections import Counter


def fuse_results(results: list[dict]) -> dict:
    if not results:
        return {
            "is_blocked": False,
            "confidence": 0.0,
            "blocked_vehicle": None,
            "blocking_vehicles": [],
        }

    votes = [r["is_blocked"] for r in results]
    blocked_votes = sum(votes)
    total = len(results)

    is_blocked = blocked_votes >= (total / 2)
    confidence = blocked_votes / total

    blocked_ids = []
    blocking_ids = []

    for r in results:
        if r.get("blocked_vehicle"):
            blocked_ids.append(r["blocked_vehicle"])
        blocking_ids.extend(r.get("blocking_vehicles", []))

    blocked_vehicle = None
    if blocked_ids:
        blocked_vehicle = Counter(blocked_ids).most_common(1)[0][0]

    blocking_vehicles = [k for k, _ in Counter(blocking_ids).most_common()]
    if blocked_vehicle in blocking_vehicles:
        blocking_vehicles.remove(blocked_vehicle)

    return {
        "is_blocked": is_blocked,
        "confidence": round(confidence, 2),
        "blocked_vehicle": blocked_vehicle,
        "blocking_vehicles": blocking_vehicles,
    }