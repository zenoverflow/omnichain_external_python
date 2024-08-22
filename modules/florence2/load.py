from modules.state import load_inference
from modules.florence2.inference import Florence2Inference, inference_name

from pydantic import BaseModel


class Florence2LoadData(BaseModel):
    """
    Task schema for loading Florence2 inference.

    Attributes:
    - device: str: The device to load the model to.
    """

    device: str


async def florence2_load(data: Florence2LoadData):
    """
    Load the Florence2 model to RAM/VRAM.
    """

    load_inference(inference_name, Florence2Inference(device=data.device))
