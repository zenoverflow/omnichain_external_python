from modules.state import get_inference
from modules.faster_whisper.inference import FasterWhisperInference, inference_name

from pydantic import BaseModel


class FasterWhisperInferenceData(BaseModel):
    """
    Task schema for FasterWhisper actions.

    Attributes:
    - audio: str: The audio to transcribe (base64 encoded)
    """

    audio: str


async def faster_whisper_action(data: FasterWhisperInferenceData):
    """
    Use FasterWhisper to transcribe audio.
    """

    inference: FasterWhisperInference = get_inference(inference_name)

    result = inference.inference(data.audio)

    return result
