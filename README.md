# Homebrew tap for ABINIT

This is a [Homebrew](https://brew.sh/) [tap](https://docs.brew.sh/Taps) for the [Abinit](https://www.abinit.org) code.

## Installing `ABINIT`

Install Homebrew and run

```
brew tap abinit/tap
brew install abinit
```

*Notes:*

- *Always use the latest Homebrew version (use* `brew upgrade`*).*
- *Bottles for all macOS versions and hardware (Intel and `Mac Silicon` arm64) are not always provided. If so, abinit will be built on the fly during installation process. The build only takes 5' on a Macbook M1 (2022).*

> If you experience difficulties with precompiled bottles (following an update of homebrew, for example), you can force the re-compilation of abinit:
> ```brew install --build-from-source abinit```
> If you experience an error like `curl: (60) SSL certificate problem`, try this:
> ```HOMEBREW_FORCE_BREWED_CURL=1 brew install abinit```

## Installing post-processing tool `AGATE`

This tap also contains [agate](https://github.com/piti-diablotin/agate) (**A**binit **G**raphical **A**nalysis **T**ool `E`ngine) and its Qt interface [qAgate](https://github.com/piti-diablotin/qAgate).
You can install `agate` with
```
brew install agate
```
Independently, you can install `qAgate` (graphical interface for `agate`) with
```
brew install qagate
```
The `.app` will be place in `${HOMEBREW_PREFIX}/opt/qagate/bin`
To make the app appear in the launcher, you can then make a symlink to `/Applications/`. Just type: `ln -s ${HOMEBREW_PREFIX}/opt/qagate/bin/qAgate.app /Applications`.

You also can install `qagate` via a `cask`(a precompiled version):
```
brew install --cask qagate
```
The app will directly appear in the launcher.
> **Note**: if macOS complains because `qAgate` is from an unidentified developer, [allow it in the MacOS settings](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unidentified-developer-mh40616/mac).  
> If macOS reports that the app is damaged, type `sudo spctl --master-disable` in a terminal and select _Anywhere_ In `Settings/Privacy & Security/Security` (see [this](https://osxdaily.com/2022/11/17/allow-apps-downloaded-open-anywhere-macos/)).

## Building bottles
*This section is for the* `abinit maintainers`*...*

Homebrew formulae can include compiled binaries, which it calls "bottles". To build a new bottle (perhaps for a new operating system or Abinit release):

1. `brew install --build-bottle abinit` (or `brew install --build-bottle abinit --with-testsuite` to install the whole test suite).
1. `brew bottle abinit --keep-old --root-url=http://forge.abinit.org/homebrew` and note the lines of output it gives you (root_url, sha256, etc.).
1. Rename the bottle to use a single hyphen (e.g. `abinit--9.10.1.catalina.bottle.tar.gz` to  `abinit-9.10.1.catalina.bottle.tar.gz`). On linux, `run sha256sum` on the renamed file, and use the result to replace the bottle hash from previous item.
1. Upload the resulting file to http://forge.abinit.org/homebrew.
1. Update the `abinit` formula with the bottle SHA and tag, in the bottle section with the custom URL.

New installs will then use this bottle.
