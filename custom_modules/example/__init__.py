from fastapi import FastAPI
from pydantic import BaseModel


class ExampleModel(BaseModel):
    """
    An example model for the example module.
    """

    custom_parameter: str | None


def setup(app: FastAPI):
    """
    The setup function for the example module.
    """

    def echo(data: ExampleModel | None = None):
        """
        A simple route that echoes back the custom parameter.
        """

        custom_parameter = data.custom_parameter if data else None

        return {"message": custom_parameter if custom_parameter else "Hello there!"}

    # Add the hello route to the app
    app.post("/example/echo")(echo)
