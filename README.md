# Deck

**Deck** is a local hub for teams that work across several repositories: one executable that is both a CLI
(`deck`) and a web panel running only on your machine (`http://localhost:4004`). Git across all repos,
tests, mocks, databases, boards, SSH keys, logins and AI accounts (Claude Code per project, Gemini) in one
place. Nothing is sent to a hosted backend.

This repository only publishes the **releases** (executables for macOS, Linux and Windows), the installers
and the license.

## Install

macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/thecodecodex/deck/main/install.sh | bash
```

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/thecodecodex/deck/main/install.ps1 | iex
```

The installer downloads the latest release to `~/.deck/bin`, checks its SHA-256, adds **Deck** to your
system's app list (Launchpad/Spotlight, the applications menu or the Start menu), opens a setup page in your
browser where one click installs Deck's own window (so it shows up with Deck's icon), and runs `deck setup all`, a
step-by-step check of your machine. No GitHub account is needed.

- `DECK_NO_SETUP=1` skips the setup assistant, `DECK_NO_APP=1` the app shortcut and `DECK_NO_OPEN=1` the setup page.
- Prefer manual install? Download the file for your system from
  [Releases](https://github.com/thecodecodex/deck/releases/latest) and compare it with `checksums.txt`.

## Updates

`deck update` (and the panel, in the background) installs new versions from this repository. Every release's
`checksums.txt` is signed (Ed25519, `checksums.txt.sig`) and the updater refuses a release whose signature
does not match the key built into the executable. `deck update --rollback` goes back to the previous version.

Channels: `estavel` (stable, default) and `dev` (every change, marked as pre-release):
`deck update --canal dev`.

## License

Deck is free to use, copy and redistribute, **but it may not be sold**. It is licensed under the
[PolyForm Noncommercial License 1.0.0](LICENSE) with an additional permission:

- ✅ Use it for anything, at home or at work, including inside companies.
- ✅ Share copies with anyone, free of charge, keeping the `LICENSE` file.
- ❌ Selling it, charging for downloads, installation, hosting or access, or bundling it in a paid product or
  service.

Any other commercial use needs a separate written license. See [LICENSE](LICENSE) for the binding terms.

> **Em português:** o Deck é livre para usar (inclusive no trabalho e em empresas), copiar e redistribuir
> gratuitamente, mas é proibido vendê-lo, cobrar por ele ou incluí-lo em produto ou serviço pago. Os termos
> que valem são os do arquivo [LICENSE](LICENSE).
