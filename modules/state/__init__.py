import gc
from fastapi import HTTPException

state = dict()


def unload_inference(inference_name: str) -> None:
    """
    Unload inference module into state.
    """

    if inference_name in state:
        del state[inference_name]
    gc.collect()


def load_inference(inference_name: str, inference: any) -> None:
    """
    Load inference module into state.
    """

    if inference_name in state:
        unload_inference(inference_name)
    state[inference_name] = inference


def get_inference(inference_name: str) -> any:
    """
    Get inference module from state.

    Raises:
        HTTPException: Inference module is not loaded.
    """

    if inference_name not in state:
        raise HTTPException(status_code=400, detail="Inference module is not loaded.")
    return state[inference_name]