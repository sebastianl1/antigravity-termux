import json
import re
from pathlib import Path

ROOT = Path(__file__).parent.parent


def load():
    return json.loads((ROOT / "versions.json").read_text())


def test_structure():
    d = load()
    assert d["version"].startswith("v")
    assert d["sha256"]
    assert isinstance(d["urls"], list) and len(d["urls"]) >= 1


def test_sha256_hex():
    assert re.fullmatch(r"[0-9a-f]{64}", load()["sha256"])


def test_urls_https():
    for u in load()["urls"]:
        assert u.startswith("https://")


def test_urls_contienen_version():
    d = load()
    for u in d["urls"]:
        assert d["version"] in u or "agy-" in u
