from modules.state import load_inference
from modules.florence2.inference import Florence2Inference, inference_name

from pydantic import BaseModel


class Florence2LoadData(BaseModel):
    """
    Task schema for loading Florence2 inference.

    Attributes:
    - device: str: The device to load the model to.
    - model: str: The model to download from HuggingFace hub.
    """

    device: str
    model: str | None = None


async def florence2_load(data: Florence2LoadData):
    """
    Load the Florence2 model to RAM/VRAM.
    """

    if data.model is not None:
        load_inference(
            inference_name,
            Florence2Inference(device=data.device, model=data.model),
        )
    else:
        load_inference(
            inference_name,
            Florence2Inference(device=data.device),
        )
