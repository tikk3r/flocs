#!/usr/bin/env python
import json
import os
from typing import Optional

import typer

from . import linc_runner, vlbi_runner


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
