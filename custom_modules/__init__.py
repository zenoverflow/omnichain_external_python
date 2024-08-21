def get_custom_modules():
    import os
    import importlib

    # Get the current directory
    current_dir = os.path.dirname(__file__)

    modules = []

    # Iterate over all files in the current directory
    for file in os.listdir(current_dir):
        # Check if the file is a Python module
        if file.endswith(".py") and file != "__init__.py":
            # Get the module name by removing the file extension
            module_name = file[:-3]

            # Import the module dynamically
            module = importlib.import_module(f".{module_name}", package=__name__)

            # Add the module to the list
            modules.append(module.setup)

    return modules
