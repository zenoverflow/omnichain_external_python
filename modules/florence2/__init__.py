from fastapi import FastAPI

from modules.florence2.load import florence2_load
from modules.florence2.unload import florence2_unload
from modules.florence2.action import florence2_action


def setup_florence2(app: FastAPI) -> None:
    """
    Setup Florence2 routes.
    """

    app.post("/florence2/load/{device}")(florence2_load)

    app.post("/florence2/unload")(florence2_unload)

    app.post("/florence2/action")(florence2_action)
