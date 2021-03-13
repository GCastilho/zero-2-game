# Write Your Own 64-bit Operating System Kernel From Scratch

This respository holds all the source code for [this YouTube tutorial series](https://www.youtube.com/playlist?list=PLZQftyCk7_SeZRitx5MjBKzTtvk0pHMtp).

You can find the revision for a specific episode on [this page](https://github.com/davidcallanan/yt-os-series/tags).

Considering supporting this work via [my Patreon page](http://patreon.com/codepulse).

## Prerequisites

 - A text editor such as [VS Code](https://code.visualstudio.com/).
 - [Docker](https://www.docker.com/) for creating our build-environment.
 - [Qemu](https://www.qemu.org/) for emulating our operating system.
   - Remember to add Qemu to the path so that you can access it from your command-line. ([Windows instructions here](https://dev.to/whaleshark271/using-qemu-on-windows-10-home-edition-4062))

## Setup

Build an image for our build-environment:
 - `docker build buildenv -t myos-buildenv`

or setup build environment:

Required packages
-----------------

First, install the required packages. On linux, use your package distribution. On a Mac, [install brew](http://brew.sh/) if
you didn't do it on lesson 00, and get those packages with `brew install`

- gmp
- mpfr
- libmpc
- gcc

Yes, we will need `gcc` to build our cross-compiled `gcc`, especially on a Mac where gcc has been deprecated for `clang`

Once installed, find where your packaged gcc is (remember, not clang) and export it. For example:

```
export CC=$(which gcc)
export LD=$(which gcc)
```

We will need to build binutils and a cross-compiled gcc, and we will put them into `/usr/local/x86_64elfgcc`, so
let's export some paths now. Feel free to change them to your liking.

```
export PREFIX="/usr/local/x86_64elfgcc"
export TARGET=x86_64-elf
export PATH="$PREFIX/bin:$PATH"
```

binutils
--------

Remember: always be careful before pasting walls of text from the internet. I recommend copying line by line.

```sh
mkdir /tmp/src
cd /tmp/src
wget http://ftp.gnu.org/gnu/binutils/binutils-2.31.tar.gz # If the link 404's, look for a more recent version
tar -xf binutils-2.31.tar.gz
mkdir binutils-build
cd binutils-build
../binutils-2.31/configure --target=$TARGET --enable-interwork --enable-multilib --disable-nls --disable-werror --prefix=$PREFIX 2>&1 | tee configure.log
make all install 2>&1 | tee make.log
```

gcc
---
```sh
cd /tmp/src
wget http://ftp.gnu.org/gnu/gcc/gcc-8.3.0/gcc-8.3.0.tar.gz
tar -xf gcc-8.3.0.tar.gz
mkdir gcc-build
cd gcc-build
../gcc-8.3.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --disable-libssp --enable-languages=c --without-headers
make all-gcc 
make all-target-libgcc 
make install-gcc 
make install-target-libgcc 
```

That's it! You should have all the GNU binutils and the compiler at `/usr/local/x86_64elfgcc/bin`, prefixed by `x86_64-elf-` to avoid
collisions with your system's compiler and binutils.

You may want to add the `$PATH` to your `.bashrc`. From now on, on this tutorial, we will explicitly use the prefixes when using
the cross-compiled gcc.

## Build

Enter build environment:
 - Linux or MacOS: `docker run --rm -it -v "$(pwd)":/root/env myos-buildenv`
 - Windows (CMD): `docker run --rm -it -v "%cd%":/root/env myos-buildenv`
 - Windows (PowerShell): `docker run --rm -it -v "${pwd}:/root/env" myos-buildenv`
 - NOTE: If you are having trouble with an unshared drive, ensure your docker daemon has access to the drive you're development environment is in. For Docker Desktop, this is in "Settings > Shared Drives" or "Settings > Resources > File Sharing".

Build for x86 (other architectures may come in the future):
 - `make build-x86_64`

To leave the build environment, enter `exit`.

## Emulate

You can emulate your operating system using [Qemu](https://www.qemu.org/): (Don't forget to add qemu to your path!)

 - `qemu-system-x86_64 -cdrom dist/x86_64/kernel.iso`
 - NOTE: When building your operating system, if changes to your code fail to compile, ensure your QEMU emulator has been closed, as this will block writing to `kernel.iso`.

Alternatively, you should be able to load the operating system on a USB drive and boot into it when you turn on your computer. (I haven't actually tested this yet.)

## Cleanup

Remove the build-evironment image:
 - `docker rmi myos-buildenv -f`
