import torch
from PIL import Image
from transformers import AutoProcessor, LlavaForConditionalGeneration

MODEL_ID = "llava-hf/llava-1.5-7b-hf"

processor = AutoProcessor.from_pretrained(MODEL_ID)

llava_model = LlavaForConditionalGeneration.from_pretrained(
    MODEL_ID,
    torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
    device_map="auto"
)

PROMPT = """
You are analyzing a parking scene.

Vehicles are labeled as v1, v2, v3, etc. You MUST ONLY use these IDs.
Do not invent new IDs.

Answer:
1. Is any vehicle blocked and unable to move?
2. Which vehicle is blocked?
3. Which vehicles are blocking it?

Respond exactly in this format:

blocked: yes/no
blocked_car: v1
blocking_cars: [v2, v3]
"""


def ask_llava(image_rgb, scene_text: str) -> str:
    pil_image = Image.fromarray(image_rgb)

    full_prompt = f"""
Scene:
{scene_text}

{PROMPT}
"""

    inputs = processor(
        text=f"USER: <image>\n{full_prompt}\nASSISTANT:",
        images=pil_image,
        return_tensors="pt"
    )

    inputs = {
        k: v.to(llava_model.device) if hasattr(v, "to") else v
        for k, v in inputs.items()
    }

    with torch.no_grad():
        output = llava_model.generate(
            **inputs,
            max_new_tokens=200,
            do_sample=False
        )

    return processor.decode(output[0], skip_special_tokens=True)