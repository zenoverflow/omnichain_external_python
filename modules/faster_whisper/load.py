from modules.state import load_inference
from modules.faster_whisper.inference import FasterWhisperInference, inference_name

from pydantic import BaseModel


class FasterWhisperData(BaseModel):
    """
    Task schema for loading FasterWhisper inference.

    Attributes:
    - model: str: The model size to download from HuggingFace hub.
    - device: str: The device to load the model to.
    """

    model: str
    device: str
    force_reload: bool = True


async def faster_whisper_load(data: FasterWhisperData):
    """
    Load a FasterWhisper model to RAM/VRAM.
    """

    load_inference(
        inference_name,
        FasterWhisperInference(model=data.model, device=data.device),
        force_reload=data.force_reload,
    )
