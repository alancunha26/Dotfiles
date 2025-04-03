# Dotfiles for Windows 11

First you need to ensure _winget_ is installed. You can install it from Microsoft
Store under the name "App Installer".

> ![warning]
> Not all features are supported on Windows. Some examples ara:
>
> - Note taking with zk
> - Ltex for grammar (future)

## Install Base Packages

First you need to install git.

```shell
winget install git
```

Then you can install neovim.

```shell
winget install Neovim.Neovim
```

Install the clipboard manager for neovim clipboard integration on windows:

```shell
winget install --id=equalsraf.win32yank  -e
```

You also will need Chocolatey to install the remaining packages.

```shell
winget install Chocolatey
```

After that you will need to open Powershell as administrator and install the
following dependencies:

```shell
choco install -y ripgrep make mingw fd unzip gzip wget fzf nvm luarocks
```

## Install Node, npm, yarn and pnpm

```shell
nvm install 23.10.0
```

Setup the current node version:

```shell
nvm use 23.10.0
```

Then install yarn and pnpm globally.

```shell
npm i -g pnpm yarn
```

## Install the Dotfiles

I don't want to lose too much timing tinkering with `ps1` files, so I decided to
use this [dotifiles](https://github.com/rhysd/dotfiles/releases) manager.
Download the binaries and put the `.exe` file on `~/.bin`.

Then clone this repository to wherever you see fit.

```shell
git clone git@github.com:alancunha26/Dotfiles.git ~/.dotfiles
```

Open Powershell as administrator and from the `~/.dotfiles` directory run the `dotfiles.exe` to symlink the correct files.

```shell
~/.bin/dotfiles.exe link
```
