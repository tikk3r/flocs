#!/usr/bin/env python
import typer

from . import linc_runner, vlbi_runner

app = typer.Typer(add_completion=False)
app.add_typer(linc_runner.app, name="linc")
app.add_typer(vlbi_runner.app, name="vlbi")

def main():
    app()

if __name__ == "__main__":
    main()
# vim: ft=python
