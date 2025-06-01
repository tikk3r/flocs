import typer
from typing_extensions import Annotated

app = typer.Typer(add_completion=False)


@app.command()
def calibrator(
    mspath: Annotated[str, typer.Argument(help="Directory where MSes are located.")],
    save_raw_solutions: Annotated[bool, typer.Argument(help="Save the intermediate, raw solution tables for (bandpass, faraday, ion, polalign)."])
):
    pass


@app.command()
def target():
    pass


if __name__ == "__main__":
    app()
