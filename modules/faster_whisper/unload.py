from modules.state import unload_inference
from modules.faster_whisper.inference import inference_name


async def faster_whisper_unload():
    """
    Unload the FasterWhisper model from RAM/VRAM.
    """

    unload_inference(inference_name)
