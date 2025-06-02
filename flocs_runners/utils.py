from typing import Optional
import json


def cwl_file(entry: str) -> Optional[str]:
   """Create a CWL-friendly file entry."""
   if entry is None:
       return None
   if entry.lower() == "null":
       return None
   else:
       return json.loads(f'{{"class": "File", "path":"{os.path.abspath(entry)}"}}')

def cwl_dir(entry: str) -> Optional[str]:
   """Create a CWL-friendly file entry."""
   if entry is None:
       return None
   if entry.lower() == "null":
       return None
   else:
       return json.loads(f'{{"class": "File", "path":"{os.path.abspath(entry)}"}}')

