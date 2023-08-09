import sys
import os
import pyqt5ac

def compile_resource(qrc_file, output_file):
    if not os.path.isfile(qrc_file):
        print(f"Error: {qrc_file} does not exist.")
        sys.exit(1)

    try:
        pyqt5ac.main(["resources.py", "resources1.qrc"])
    except Exception as e:
        print(f"Error compiling {qrc_file}: {e}")
        sys.exit(1)

if __name__ == "__main__":
    qrc_file = "resources.qrc"
    output_file = "libs/resources.py"

    compile_resource(qrc_file, output_file)
    print(f"Successfully compiled {qrc_file} to {output_file}")

pyqt5ac.main(rccOptions='', uicOptions='--from-imports', force=False, initPackage=True, config='',
             ioPaths=[['resources.qrc', 'libs/resources.py']])