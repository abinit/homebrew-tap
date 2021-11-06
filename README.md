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
- *Bottles for `Mac Silicon` (arm64) are not always provided. If so, abinit will be built on the fly during installation process. The build only takes 6' on a Macbook M1 (2020).*
- `abinit v8` *is still accessible via* `brew install abinit8`*.*

> If you experience difficulties with precompiled bottles (following an update of homebrew, for example), you can force the re-compilation of abinit:
> ```brew install --build-from-source abinit```
> If you experience an error like `curl: (60) SSL certificate problem`, try this:
> ```HOMEBREW_FORCE_BREWED_CURL=1 brew install abinit```

## Installing post-processing tool `AGATE`

This tap also contains [agate](https://github.com/piti-diablotin/agate) and its Qt interface [qAgate](https://github.com/piti-diablotin/qAgate).
You can install `agate` with

```
brew install agate # with gnuplot support
# or
brew install agate --without-gnuplot # without gnuplot support
```

*You can still install gnuplot later if you wish.*

Independently, you can install qAgate with
```
brew install --cask qagate # Recommanded  precompiled version
#or
brew install qagate # Formulae that compiles qAgate
```

In the case of the `Formulae`, the `.app` will be place in `/usr/local/Cellar/qagate/X.X.X/bin`
You can then make a symlink to `/Applications/` if you want.

For instance for version 1.1.1 `ln -s /usr/local/Cellar/qagate/1.1.1/bin/qAgate.app /Applications/`.
The app will then appear in the launcher.

In the case of the `cask` nothing has to be done. The app will be in the launcher.

## Building bottles
*This section is for the* `abinit maintainers`*...*

Homebrew formulae can include compiled binaries, which it calls "bottles". To build a new bottle (perhaps for a new operating system or Abinit release):

1. `brew install --build-bottle abinit --with-testsuite`
1. `brew bottle abinit --keep-old --root-url=http://forge.abinit.org/homebrew` and note the lines of output it gives you (root_url, sha256, etc.).
1. Rename the bottle to use a single hyphen (e.g. `abinit--8.10.3.catalina.bottle.tar.gz` to  `abinit-8.10.3.catalina.bottle.tar.gz`). On linux, `run sha256sum` on the renamed file, and use the result to replace the bottle hash from previous item.
1. Upload the resulting file to http://forge.abinit.org/homebrew.
1. Update the `abinit` formula with the bottle SHA and tag, in the bottle section with the custom URL.

New installs will then use this bottle.
