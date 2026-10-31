"""Check release inputs and run focused Lua 5.1 mocks; no engine test is implied."""
import argparse
import sys
from pathlib import Path

from build_release import ROOT, SCRIPT, read_inputs, sha256


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lua-deps", type=Path, help="Existing local directory containing Lupa")
    args = parser.parse_args()
    if args.lua_deps:
        sys.path.insert(0, str(args.lua_deps.resolve()))
    try:
        from lupa.lua51 import LuaRuntime
    except ImportError as error:
        raise SystemExit("Lua checks require Lupa's lua51 backend; install Lupa or supply --lua-deps PATH") from error
    _, payload = read_inputs()
    original_readme = (ROOT / "README.txt").read_bytes()
    if sha256(original_readme) != "999706d802fee73e76c2cc0727ab7007a539c015c5e23e4b98580716dfa7df4d":
        raise ValueError("Historical README.txt differs from the original v1.4 document")
    lua = LuaRuntime(unpack_returned_tuples=True)
    source = payload[SCRIPT].decode("utf-8")
    lua.execute("assert(loadstring(...))", source)
    lua.globals().SCIENCE_SOURCE = source
    lua.execute((ROOT / "tests/release_spec.lua").read_text(encoding="utf-8"))
    print("PASS: release inputs; original gameplay and README; Lua 5.1 syntax and focused mocks")
    print("No X-Ray engine, MO2 VFS, DLTX or in-game validation was performed.")


if __name__ == "__main__":
    main()
