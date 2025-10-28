#!/usr/bin/env python
import os
from concurrent.futures import ProcessPoolExecutor
from typing import Iterable
import typer
from enum import Enum
from stager_access import get_macaroons, get_webdav_urls_requested
from typer import Argument, Option
from typing_extensions import Annotated

# app = typer.Typer(add_completion=False)


class LTASite(Enum):
    JUELICH = "Juelich"
    POZNAN = "Poznan"


class Downloader:
    def __init__(self, urls: Iterable, macaroons: dict):
        """Initialise a Downloader object.

        Args:
            urls (list): a list (or other iterable) of URLs to download.
            macaroons (dict): dictionary with maracoons for the various LTA sites.
        """
        self.macaroons = macaroons
        self.urls = urls

    def download_url(self, url: str):
        """Download the MS pointed to by the URL.

        Args:
            url (str): URL to download.

        Raises:
            RuntimeError: when encountering an unknown LTA site.
        """
        site = None
        outname = url.split("/")[-1]
        if "juelich" in url:
            site = LTASite.JUELICH
        if "psnc" in url:
            site = LTASite.POZNAN
        if not site:
            raise RuntimeError("Unknown LTA site encountered.")
        print(
            f"wget --no-clobber --retry-on-http-error 401,500 --check-certificate=off {url}?authz={self.macaroons[site.value]} -O {outname}"
        )
        os.system(
            f"wget --no-clobber --retry-on-http-error 401,500 --check-certificate=off {url}?authz={self.macaroons[site.value]} -O {outname}"
        )

    def download_all(self, max_workers: int):
        """Download all URLs belonging to the instance.

        Args:
            max_workers (int):
        """
        with ProcessPoolExecutor(max_workers=max_workers) as pex:
            pex.map(self.download_url, self.urls)


def download(
    stage_id: Annotated[str, Argument(help="StageIt staging ID.")],
    parallel_downloads: Annotated[
        int, Option(help="Maximum number of parallel downloads.")
    ] = 1,
):
    """Download data from the LTA that was staged via the StageIt service."""
    urls = get_webdav_urls_requested(stage_id)
    macaroons = get_macaroons(stage_id)
    dl = Downloader(urls, macaroons[0])
    dl.download_all(parallel_downloads)


def main():
    typer.run(download)


if __name__ == "__main__":
    typer.run(download)
