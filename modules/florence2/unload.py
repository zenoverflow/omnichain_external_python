from modules.state import unload_inference
from modules.florence2.inference import inference_name


async def florence2_unload():
    """
    Unload the Florence2 model from RAM/VRAM.
    """

    unload_inference(inference_name)
