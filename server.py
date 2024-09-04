import sys

sys.dont_write_bytecode = True


def setup_cuda_env():
    import os

    os.environ["LD_LIBRARY_PATH"] = os.path.join(
        os.getcwd(), "miniconda", "envs", "oc_external", "lib"
    )


def version_check():
    import requests

    try:
        res = requests.get(
            "https://api.github.com/repos/zenoverflow/omnichain_external_python/contents/VERSION"
        )

        if res.status_code != 200:
            raise Exception(res.text)

        with open("VERSION", "r") as file_version:
            current_version = file_version.read().strip()

        latest_version = res.text.strip()

        if latest_version != current_version:
            message = " ".join(
                [
                    f"A new version is available (v{current_version} => v{latest_version})",
                    "To get the latest fixes and features, shut down the server",
                    "and run `setup.sh` (or `setup.bat` on Windows) to update.",
                ]
            )
            print(message)
    except Exception as e:
        print("Failed to check for updates:", e)


if __name__ == "__main__":
    version_check()
    setup_cuda_env()

    from modules.florence2 import setup_florence2
    from modules.faster_whisper import setup_faster_whisper

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
    setup_faster_whisper(app)

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
