def get_custom_modules():
    import os
    import importlib

    # Get the current directory
    current_dir = os.path.dirname(__file__)

    modules = []

    # Iterate over all directories in the current directory
    for directory in os.listdir(current_dir):
        # Check if the directory is a package
        if os.path.isdir(os.path.join(current_dir, directory)):
            # Import the module dynamically
            module = importlib.import_module(f".{directory}", package=__name__)

            # Add the module to the list
            modules.append(module.setup)

    return modules
