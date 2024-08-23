import sys

sys.dont_write_bytecode = True


if __name__ == "__main__":
    from modules.florence2 import setup_florence2

    from custom_modules import get_custom_modules

    import argparse
    import uvicorn
    from fastapi import FastAPI, Response

    # Parse CLI arguments
    parser = argparse.ArgumentParser(description="Run the server.")
    parser.add_argument(
        "--host",
        type=str,
        default="127.0.0.1",
        help="Host address for the server to listen on.",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=12619,
        help="Port number for the server to listen on.",
    )
    args = parser.parse_args()

    app = FastAPI()

    # Setup ping route
    @app.get("/ping")
    async def ping():
        return Response(status_code=200)

    # Setup internal module routes.
    setup_florence2(app)

    # Setup custom module routes.
    for custom_module_setup in get_custom_modules():
        custom_module_setup(app)

    uvicorn.run(
        app,
        host=args.host,
        port=args.port,
        timeout_keep_alive=sys.maxsize - 1,
        timeout_graceful_shutdown=None,
        ws_ping_timeout=None,
    )
