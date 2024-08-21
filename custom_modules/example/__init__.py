from fastapi import FastAPI


def setup(app: FastAPI):
    """
    The setup function for the example module.
    """

    def hello():
        """
        A simple hello world route.
        """

        return {"message": "Hello there!"}

    # Add the hello route to the app
    app.post("/example/hello")(hello)
