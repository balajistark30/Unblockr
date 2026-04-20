import cv2


def load_image_rgb(path: str):
    image = cv2.imread(path)
    if image is None:
        raise ValueError(f"Failed to load image: {path}")
    return cv2.cvtColor(image, cv2.COLOR_BGR2RGB)


def draw_boxes(image, vehicles: list[dict]):
    img = image.copy()

    for v in vehicles:
        x1, y1, x2, y2 = map(int, v["bbox"])

        cv2.rectangle(img, (x1, y1), (x2, y2), (0, 255, 0), 2)
        cv2.putText(
            img,
            v["id"],
            (x1, max(y1 - 10, 20)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.7,
            (0, 255, 0),
            2
        )

    return img


def get_center(bbox):
    x1, y1, x2, y2 = bbox
    return ((x1 + x2) / 2, (y1 + y2) / 2)


def build_scene(vehicles: list[dict]) -> str:
    if not vehicles:
        return "No vehicles detected."

    lines = []
    for v in vehicles:
        cx, cy = get_center(v["bbox"])
        lines.append(f"{v['id']} ({v['class_name']}) at ({int(cx)}, {int(cy)})")

    return "Vehicles:\n" + "\n".join(lines)