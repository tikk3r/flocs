#!/usr/bin/env python
import json
import os
from typing import Optional

import typer

from . import linc_runner, vlbi_runner


def main():
    app = typer.Typer(add_completion=False)
    app.add_typer(linc_runner.app, name="linc")
    app.add_typer(vlbi_runner.app, name="vlbi")

    app()


if __name__ == "__main__":
    main()
# vim: ft=python
