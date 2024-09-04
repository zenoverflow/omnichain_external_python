from fastapi import FastAPI

from modules.faster_whisper.load import faster_whisper_load
from modules.faster_whisper.unload import faster_whisper_unload
from modules.faster_whisper.action import faster_whisper_action


def setup_faster_whisper(app: FastAPI) -> None:
    """
    Setup FasterWhisper routes.
    """

    app.post("/faster_whisper/load/")(faster_whisper_load)

    app.post("/faster_whisper/unload")(faster_whisper_unload)

    app.post("/faster_whisper/action")(faster_whisper_action)
