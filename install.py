"""Install the project's director skill for the current user, using only Python's standard library."""
import argparse
import filecmp
import shutil
import sys
from uuid import uuid4
from pathlib import Path

SOURCE = Path(__file__).resolve().parent / ".agents" / "skills" / "film-director"
CLIENTS = {"codex": ".agents", "claude": ".claude"}


def files_under(root):
    return {path.relative_to(root) for path in root.rglob("*") if path.is_file()}


def install(client, home):
    parent = home / CLIENTS[client] / "skills"
    target = parent / SOURCE.name
    files = files_under(SOURCE)
    if target.exists():
        if target.is_dir() and files == files_under(target) and all(
            filecmp.cmp(SOURCE / name, target / name, shallow=False) for name in files
        ):
            return f"{client}: already installed at {target}"
        raise FileExistsError(f"{target} already exists with different contents; preserved it.")
    parent.mkdir(parents=True, exist_ok=True)
    staged = parent / (".install-film-director-" + uuid4().hex)
    staged.mkdir()
    try:
        shutil.copytree(SOURCE, staged, dirs_exist_ok=True)
        if not all(filecmp.cmp(SOURCE / p, staged / p, shallow=False) for p in files):
            raise OSError("Copy verification failed.")
        staged.rename(target)
    finally:
        if staged.exists():
            shutil.rmtree(staged)
    return f"{client}: installed at {target}"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--client", choices=["codex", "claude", "both"], default="both")
    parser.add_argument("--home", type=Path, default=Path.home(), help="User home or an isolated test directory")
    args = parser.parse_args()
    failures = []
    for client in CLIENTS if args.client == "both" else [args.client]:
        try:
            print(install(client, args.home.resolve()))
        except OSError as error:
            failures.append(client)
            print(f"{client}: {error}", file=sys.stderr)
    return int(bool(failures))


if __name__ == "__main__":
    raise SystemExit(main())

