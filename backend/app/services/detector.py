from ultralytics import YOLO

VEHICLE_CLASSES = {2, 3, 5, 7}

CLASS_NAME_MAP = {
    2: "car",
    3: "motorcycle",
    5: "bus",
    7: "truck",
}

yolo_model = YOLO("yolov8n.pt")


def detect_vehicles(image_path: str) -> list[dict]:
    results = yolo_model(image_path, verbose=False)
    vehicles = []

    for r in results:
        for box in r.boxes:
            cls = int(box.cls[0])
            conf = float(box.conf[0])
            x1, y1, x2, y2 = box.xyxy[0].tolist()

            if cls in VEHICLE_CLASSES and conf > 0.5:
                vehicles.append({
                    "id": f"v{len(vehicles)+1}",
                    "class_name": CLASS_NAME_MAP.get(cls, "vehicle"),
                    "confidence": round(conf, 2),
                    "bbox": [x1, y1, x2, y2],
                })

    return vehicles