#!/usr/bin/env python
import json
import os
from dataclasses import dataclass
from typing import Any, Optional

import typer

from . import linc_runner, vlbi_runner


@dataclass
class cwl_file:
    value: Any

    def __init__(self, entry: Optional[str]):
        """Create a CWL-friendly file entry."""
        if entry is None:
            self.value = None
        if entry.lower() == "null":
            self.value = None
        else:
            self.value = json.loads(
                f'{{"class": "File", "path":"{os.path.abspath(entry)}"}}'
            )


# def cwl_file(entry: str) -> Optional[str]:
#    """Create a CWL-friendly file entry."""
#    if entry is None:
#        return None
#    if entry.lower() == "null":
#        return None
#    else:
#        return json.loads(f'{{"class": "File", "path":"{os.path.abspath(entry)}"}}')
#
#
# def cwl_dir(entry: str) -> Optional[str]:
#    """Create a CWL-friendly directory entry."""
#    if entry is None:
#        return None
#    if entry.lower() == "null":
#        return None
#    else:
#        return json.loads(
#            f'{{"class": "Directory", "path":"{os.path.abspath(entry)}"}}'
#        )


def main():
    if "LINC_DATA_ROOT" not in os.environ:
        raise ValueError(
            "WARNING: LINC_DATA_ROOT environment variable has not been set. Cannot generate $LINC_DATA_ROOT/.versions file."
        )
    app = typer.Typer(add_completion=False)
    app.add_typer(linc_runner.app, name="linc")
    app.add_typer(vlbi_runner.app, name="vlbi")

    app()


if __name__ == "__main__":
    main()
# vim: ft=python
