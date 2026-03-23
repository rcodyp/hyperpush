# Mesh Language

[![VS Code Marketplace Version](https://img.shields.io/visual-studio-marketplace/v/OpenWorthTechnologies.mesh-lang)](https://marketplace.visualstudio.com/items?itemName=OpenWorthTechnologies.mesh-lang)
[![VS Code Marketplace Installs](https://img.shields.io/visual-studio-marketplace/i/OpenWorthTechnologies.mesh-lang)](https://marketplace.visualstudio.com/items?itemName=OpenWorthTechnologies.mesh-lang)

Language support for [Mesh](https://meshlang.dev) -- an expressive, readable programming language with built-in concurrency via actors and supervision trees.

## Features

- **Syntax Highlighting** -- comprehensive TextMate grammar with scoping for keywords, types, literals, comments, and module-qualified calls
- **Language Configuration** -- bracket matching, auto-closing pairs, and Mesh-specific indentation for `do`/`end` blocks
- **Verified LSP Diagnostics** -- real-time parse and type errors from the Mesh compiler
- **Verified Hover** -- inferred type information on hover
- **Verified Go to Definition** -- jump to definitions across files
- **Verified Document Formatting** -- format the current Mesh document through `meshc lsp`
- **Verified Signature Help** -- parameter hints with active-parameter tracking for function calls

The current transport-level regression suite exercises the LSP path over real stdio JSON-RPC against `reference-backend/`, so the documented editor experience is tied to the same backend-shaped proof as the CLI tooling.

## Installation

Build and install the current packaged extension from source:

```sh
npm install
npm run compile
npm run package
code --install-extension mesh-lang-0.3.0.vsix
```

For repeat local installs, you can also run:

```sh
npm run install-local
```

## Requirements

The Mesh compiler (`meshc`) must be installed and available in your PATH. The extension connects to the built-in language server provided by `meshc`.

**Install meshc:**

```sh
curl -sSf https://meshlang.dev/install.sh | sh
```

## Extension Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `mesh.lsp.path` | `meshc` | Path to the meshc binary. Must be in PATH, or provide an absolute path. |

## Release Notes

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes in each release.
