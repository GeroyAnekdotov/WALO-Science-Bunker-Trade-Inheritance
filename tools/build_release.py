"""Build the unchanged v1.4 MO2 addon without publishing or replacing a different ZIP."""
import hashlib
import io
import re
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = "gamedata/scripts/zzzzzz_warfare_science_bunker_trade_fix.script"
DOCS = (
    "README.md", "CHANGELOG.md", "RELEASE_NOTES.md", "DEVELOPMENT.md",
    "INTEGRATION/WALO_AUTHOR_NOTES.md", "INTEGRATION/GAME_FILES_SHA256.txt",
)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def read_inputs():
    manifest = (ROOT / "INTEGRATION/GAME_FILES_SHA256.txt").read_text(encoding="utf-8")
    match = re.fullmatch(r"([a-f0-9]{64})  " + re.escape(SCRIPT) + r"\n?", manifest)
    if not match:
        raise ValueError("Expected exactly one original gameplay hash entry")
    actual = {p.relative_to(ROOT).as_posix() for p in (ROOT / "gamedata").rglob("*") if p.is_file()}
    if actual != {SCRIPT}:
        raise ValueError(f"Runtime file list differs from v1.4: {sorted(actual)}")
    payload = {}
    for name in (SCRIPT, *DOCS):
        path = ROOT / name
        if path.is_symlink() or any(p.is_symlink() for p in path.parents if p != ROOT.parent):
            raise ValueError(f"Release input must not be a symlink: {name}")
        payload[name] = path.read_bytes()
    if sha256(payload[SCRIPT]) != match[1] or len(payload[SCRIPT]) != 14621:
        raise ValueError("Gameplay differs from the original v1.4 baseline")
    version_match = re.search(r'^local VERSION = "(\d+\.\d+(?:\.\d+)?)"$', payload[SCRIPT].decode("utf-8"), re.M)
    if not version_match or version_match[1] != "1.4":
        raise ValueError("Expected the established v1.4 gameplay version")
    version = version_match[1]
    filename = f"Warfare_Science_Bunker_Trade_Inheritance_{version}_FULL_MO2.zip"
    for name in DOCS:
        data = payload[name]
        text = data.decode("utf-8")
        if b"\r" in data:
            raise ValueError(f"Use checkout-stable LF endings: {name}")
        if re.search(r"^(?:<{7}|={7}|>{7})(?: |$)", text, re.M):
            raise ValueError(f"Merge marker: {name}")
        if re.search(r"\b[A-Za-z]:[\\/]", text):
            raise ValueError(f"Machine-specific path in release documentation: {name}")
        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", text):
            if re.match(r"[a-z]+://|#", target):
                continue
            resolved = ((ROOT / name).parent / target.split("#")[0]).resolve()
            if not resolved.is_relative_to(ROOT) or resolved.relative_to(ROOT).as_posix() not in payload:
                raise ValueError(f"Link is not in the release: {name}: {target}")
    for name in ("README.md", "RELEASE_NOTES.md"):
        if filename not in payload[name].decode("utf-8"):
            raise ValueError(f"Package filename/version mismatch: {name}")
    return filename, payload


def build():
    filename, payload = read_inputs()
    manifest = "".join(f"{sha256(data)}  {name}\n" for name, data in sorted(payload.items())).encode("utf-8")
    payload["RELEASE_FILES_SHA256.txt"] = manifest
    buffer = io.BytesIO()
    with ZipFile(buffer, "w", ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(payload.items()):
            entry = ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            entry.compress_type = ZIP_DEFLATED
            archive.writestr(entry, data, compresslevel=9)
    content = buffer.getvalue()
    with ZipFile(io.BytesIO(content)) as archive:
        if len(archive.infolist()) != len(payload) or set(archive.namelist()) != set(payload) or archive.testzip():
            raise ValueError("ZIP paths/CRC check failed")
        for name, data in payload.items():
            if archive.read(name) != data:
                raise ValueError(f"ZIP/source mismatch: {name}")
    target = ROOT / "dist" / filename
    if target.exists() and target.read_bytes() != content:
        raise FileExistsError(f"Different content already uses this filename; preserve the existing release: {target}")
    target.parent.mkdir(exist_ok=True)
    if not target.exists():
        with target.open("xb") as output:
            output.write(content)
    (ROOT / "RELEASE_FILES_SHA256.txt").write_bytes(manifest)
    digest = sha256(content)
    target.with_suffix(".zip.sha256").write_bytes(f"{digest}  {filename}\n".encode("utf-8"))
    print(f"PASS: original v1.4 gameplay; {len(payload)} ZIP entries; CRC; exact source equality")
    print(target)
    print(f"SHA256: {digest}")


if __name__ == "__main__":
    build()
