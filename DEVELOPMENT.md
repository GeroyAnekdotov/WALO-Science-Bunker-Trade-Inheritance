# Release preparation and packaging

## Version and original payload

The gameplay script's `local VERSION = "1.4"` is the version source. Retain the established two-part numbering and documented v1.2-v1.4 history. The first GitHub tag should be **`v1.4`**; documentation-only preparation does not increase the gameplay version.

`INTEGRATION/GAME_FILES_SHA256.txt` pins the unchanged 14,621-byte v1.4 runtime script. Its hash also matches the available installed v1.4 copy. `README.txt` is the original historical document, retained unchanged in the repository and omitted from the installable ZIP so the current README is unambiguous.

`.gitattributes` disables text conversion for the original script and README, preserving their exact bytes through Git checkout, and uses LF for new development text. No Git repository, commit, remote, tag or release is created by the tools.

## Validate and build

Use Python 3.10 or later. The packager needs only the standard library:

```powershell
python tools/build_release.py
```

The builder checks the exact runtime allowlist and baseline hash, reads the version from the script, validates packaged documentation links, creates a deterministic root-`gamedata` ZIP under ignored `dist/`, verifies CRCs and every entry against source, and writes SHA-256 manifests. Only explicit release documentation and the single gameplay file are packaged; tools, tests, Git metadata, local references and historical files are excluded.

The builder refuses to replace a different archive under an existing versioned filename. Repeating an identical build reuses the same artifact. Preserve previous releases. If an already distributed package needs different content, assign an explicit unique package revision in a deliberate future tooling/metadata change; do not silently overwrite v1.4 or bump the gameplay version for documentation alone.

For the release's Lua 5.1 syntax and mocked checks, install Lupa in your Python environment, then run:

```powershell
python tools/check_release.py
```

An optional `--lua-deps PATH` argument points to an existing local directory containing Lupa. Test dependencies are not bundled or downloaded by these tools. The checker uses Lupa's `lua51` backend and the actual unchanged gameplay script. Its mock objects validate routing, supply substitution, helper delegation, repair callbacks and throttling; they do not simulate the X-Ray engine or a running MO2 profile.

## Release checks and limits

This preparation includes a focused WALO 1.6.11 source review, unchanged gameplay/legacy README verification, Lua 5.1 syntax and mocked checks, documentation checks, deterministic packaging and ZIP/source equality. No new gameplay run is claimed. See [WALO_AUTHOR_NOTES.md](INTEGRATION/WALO_AUTHOR_NOTES.md) for findings and integration acceptance scenarios.

The project folder had no Git repository or GitHub remote at the start of preparation. In GitHub Desktop, create a repository in this existing project folder, review the included files, then make the first commit when ready. Publish to your chosen GitHub repository and visibility yourself. Create release `v1.4`, use [RELEASE_NOTES.md](RELEASE_NOTES.md), and attach the MO2 ZIP plus its `.sha256` from `dist/`. GitHub's automatic source ZIP is for source distribution; the named MO2 asset is the installation package.
