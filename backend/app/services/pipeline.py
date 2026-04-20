from app.services.detector import detect_vehicles
from app.services.vlm import ask_llava
from app.services.parser import parse_answer
from app.utils.image_utils import load_image_rgb, draw_boxes, build_scene


def run_single_image_pipeline(image_path: str) -> dict:
    image_rgb = load_image_rgb(image_path)
    vehicles = detect_vehicles(image_path)
    annotated = draw_boxes(image_rgb, vehicles)
    scene_text = build_scene(vehicles)

    raw_response = ask_llava(annotated, scene_text)
    parsed = parse_answer(raw_response)

    return {
        "image_path": image_path,
        "vehicles": vehicles,
        "scene_text": scene_text,
        "raw_response": raw_response,
        "parsed_result": parsed,
    }