from modules.state import load_inference
from modules.florence2.inference import Florence2Inference, inference_name


async def florence2_load(device: str):
    """
    Load the Florence2 model to RAM/VRAM.
    """

    load_inference(inference_name, Florence2Inference(device=device))
