# Python Tools for the Gym Tycoon Project

This directory contains Python scripts and tools designed to assist with the development and maintenance of the Gym Tycoon Roblox project.

## Getting Started with Python

### Installing Python

If you don't have Python installed on your system, follow these steps:

1.  **Download:** Go to the official Python website ([https://www.python.org/downloads/](https://www.python.org/downloads/)) and download the latest stable version of Python 3.
2.  **Run Installer:** Execute the downloaded installer.
3.  **Important:** During the installation process, make sure to check the box that says "Add Python to PATH". This ensures you can run Python from your command line.
4.  **Verify:** Open your command line or terminal and type `python --version`. You should see the version number of the Python you installed.

### Creating a Virtual Environment

Virtual environments are essential for managing dependencies and avoiding conflicts between projects. Here's how to create one:

1.  **Navigate:** Open your command line or terminal and navigate to the `tools/` directory of this project:
```
bash
    cd tools/
    
```
2.  **Create Environment:** Run the following command to create a virtual environment named `.venv` (you can name it differently if you prefer):
```
bash
    python -m venv .venv
    
```
3.  **Activate:** Activate the virtual environment. The command differs slightly depending on your operating system:
    *   **Windows:**
```
bash
        .venv\Scripts\activate
        
```
*   **macOS/Linux:**
```
bash
        source .venv/bin/activate
        
```
4. **Verify:** You should see `(.venv)` at the start of your command line, indicating that the virtual environment is active.

### Installing Dependencies

Once you have activated your virtual environment, you can install the project's dependencies:

1.  **Navigate (if not already):** Make sure you are in the `tools/` directory and that your virtual environment is active.
2.  **Install:** Run the following command to install the dependencies listed in `requirements.txt`:
    
```
bash
    pip install -r requirements.txt
    
```
## Using the Python Tools

All Python scripts for this project are located in this `tools/` directory.

### Example

The `main.py` file contains an example on how to use the tools.

## Maintaining Dependencies

When adding a new Python library to your project, remember to update the `requirements.txt` file:

1.  **Install New Library:**
```
bash
    pip install <new-library-name>
    
```
2.  **Update `requirements.txt`:**
```
bash
    pip freeze > requirements.txt
    
```
This will update the `requirements.txt` file with the new library and its version.