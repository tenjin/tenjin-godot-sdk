# Godot Asset Library listing

The addon is listed on the [Godot Asset Library](https://godotengine.org/asset-library/asset)
using the **Custom** download provider. With that provider the listing
downloads the release zip, which has the binaries CI builds. The repository
itself has none, so the default GitHub provider (which downloads a commit
archive) would install a broken addon.

`icon.png` in this folder is the listing icon (square, at least 128×128).

## Submitting (first time) or updating (each release)

Log in at https://godotengine.org/asset-library/asset/submit, or open the
existing asset and choose **Edit**. Fill in:

| Field | Value |
|-------|-------|
| Asset name | Tenjin SDK |
| Category | Addons → Scripts (or Misc) |
| Godot version | 4.3 |
| Version | the release version, e.g. `1.0.0` |
| Repository host | Custom |
| Repository URL | https://github.com/tenjin/tenjin-godot-sdk |
| Issues URL | https://github.com/tenjin/tenjin-godot-sdk/issues |
| Download URL | `https://github.com/tenjin/tenjin-godot-sdk/releases/download/<version>/tenjin-godot-sdk-<version>.zip` |
| Icon URL | https://raw.githubusercontent.com/tenjin/tenjin-godot-sdk/main/.github/assetlib/icon.png |
| License | MIT |
| Description | the first paragraphs of the README (what it does, Android/iOS, Godot 4.3+) and a link to the README for setup |

Notes:

- The repo must be public before submitting. The icon URL and download URL
  have to be reachable without authentication.
- Every update goes through moderator review again. Updating the listing
  after each release is a manual step: the Asset Library has no API for it.
- The [Godot Asset Store](https://store-beta.godotengine.org), the Asset
  Library's successor, is still in beta. When it opens to publishers, list
  the same release zip there too.
