# Contributing

Bug reports and pull requests are welcome.

## Reporting a bug

Open an issue with:

- the game (name or place id) and whether your character is R6 or R15;
- your executor and device (PC or phone);
- the message in the status line, and anything printed to the console with `[Lyra` or `[Copier` in it;
- what you did, what you expected and what happened.

Many problems depend on the game, so the game is the most useful detail. [Troubleshooting](docs/troubleshooting.md) may already explain the message.

Please report security problems, such as a share code or a synced skin that does more than change how a character looks, privately to the maintainer on the Discord linked in the Creator tab instead of in a public issue.

## Changing the code

1. Read [Architecture](docs/reference/architecture.md) and the "Parts that need care" section of [Development](docs/reference/development.md#parts-that-need-care).
2. Keep a pull request to one change. Don't reformat code you aren't changing.
3. Run `tools/check.sh` and `tests/run.sh` (see [Checking a change](docs/reference/development.md#checking-a-change)) and add checks to `tests/run.lua` for new behaviour.
4. Try the change in a real game. Say in the pull request which games and rigs you tried, or that you couldn't.
5. Update the docs when you change something a player or developer would notice: the tab's page in `docs/tabs/`, and the line links with `python3 tools/doclinks.py path/to/luau-ast --write` (see [Writing docs](docs/reference/development.md#writing-docs)). Add a line to `CHANGELOG.md`.

## What fits the project

- The script stays a single file that runs without downloading code. Changes that load code from the network, add telemetry, or add a key system or obfuscation won't be merged.
- Anything that reads outside data (saved files, share codes, synced skins) has to validate it before using it.
- Every executor function stays optional: check it with `type()` and keep the feature working, or clearly off, without it.
- Messages the player sees are in English and say what to do next.

Commit messages describe the change in a short sentence, like the existing history.

## License

Avatar Copier is licensed under the [GNU General Public License, version 3 or later](LICENSE). By sending a pull request you agree that your contribution is licensed under the same terms.
