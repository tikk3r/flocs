from typing import Annotated
import typer

app = typer.Typer(add_completion=False)

@app.command()
def delay_calibration():
    pass

@app.command()
def split_directions():
    pass

@app.command()
def setup():
    pass

@app.command()
def concatenate_flag():
    pass

@app.command()
def phaseup_concat():
    pass

@app.command()
def process_ddf():
    pass

@app.command()
def facet_subtract():
    pass

if __name__ == "__main__":
    app()
