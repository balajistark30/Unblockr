import re


def parse_answer(text: str) -> dict:
    lowered = text.lower()
    is_blocked = "yes" in lowered

    ids = re.findall(r"v\d+", lowered)

    if not ids:
        return {
            "is_blocked": False,
            "blocked_vehicle": None,
            "blocking_vehicles": [],
        }

    blocked = ids[0]
    blocking = ids[1:]

    blocking = sorted(set(blocking))
    if blocked in blocking:
        blocking.remove(blocked)

    return {
        "is_blocked": is_blocked,
        "blocked_vehicle": blocked,
        "blocking_vehicles": blocking,
    }