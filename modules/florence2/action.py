from modules.state import get_inference
from modules.florence2.inference import Florence2Inference, inference_name

from pydantic import BaseModel


class Florence2InferenceData(BaseModel):
    """
    Task schema for Florence2 actions.

    Attributes:
    - image: str: The image to use (base64 encoded)
    - text_input: str: Optional text input.
    """

    image: str
    task_prompt: str
    text_input: str


async def florence2_action(data: Florence2InferenceData):
    """
    Use Florence2 to perform an action with the given image.
    """

    inference: Florence2Inference = get_inference(inference_name)

    result = inference.inference(
        task_prompt=data.task_prompt,
        imageRaw=data.image,
        text_input=data.text_input,
    )

    return result
