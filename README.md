# Homebrew tap for ABINIT

This is a [Homebrew](https://brew.sh/) [tap](https://docs.brew.sh/Taps) for the [Abinit](https://www.abinit.org) code.

## Installing

Install Homebrew and run

```
brew tap abinit/homebrew
brew install abinit
```

## Building bottles
Homebrew formulae can include compiled binaries, which it calls "bottles". To build a new bottle (perhaps for a new operating system or Abinit release):

1. `brew install --build-bottle abinit`
1. `brew bottle abinit --keep-old --root-url=https://www.abinit.org/homebrew` and note the line of output it gives you with the bottle SHA and tag
1. Rename the bottle to use a single hyphen (e.g. `abinit--8.10.3.mojave.bottle.tar.gz` to  abinit-8.10.3.mojave.bottle.tar.gz`). At least on linux, run sha256sum on the renamed file, and use the result to replace the bottle hash from previous item.
1. Upload the resulting file to forges2.pcpm.ucl.ac.be:/data/var/www/html/plugins.
1. Update the `abinit` formula with the bottle SHA and tag, in the bottle section with the custom URL.

New installs will then use this bottle.

