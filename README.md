# Asahi Debian


<img style="float: left;" src="assets/images/asahi-linux-logo.svg" width="200" height="200" />

<img src="assets/images/debian-logo.svg" width="200" height="200" />

## What is this about ?

This project brings Debian to Apple silicon hardware which is primarily possible thanks to the honorable work of the Asahi Linux community. 

For more information on the Asahi Linux project: https://asahilinux.org/

## How to install Asahi Debian ?

It is as easy as simply opening a terminal on your Apple Silicon device and pasting the command below.

``` Shell
curl -sL https://files.christiangoeschel.com/asahi-debian/installer | sh
```

Follow the installer instructions and select your preferred partitioning setup when presented with something similar to this:

``` Shell
1. Debian 12 Bookworm Minimal Install 
2. Debian 12 Bookworm Minimal Install (LUKS)
3. Debian 12 Bookworm + KDE Plasma 
4. Debian 12 Bookworm + KDE Plasma (LUKS)
```

When the procedure terminates successfully, shutdown your device and turn it back on after 25 seconds to then complete stage 2 of the installation process.

If everything went well you should be able to reboot to your freshly installed Asahi Debian OS and enjoy all it's advantages.

## What to do after the installation ?

The installer image is build in a way so that little user intervention is needed for the initial setup. 

> If you selected the LUKS enabled installer image please note that the initial encryption key is `asahi-debian`.
> You can change the key with the `myluks` tool in the terminal.

A priviliged user called `asahi` will be available after boot with the password `asahi-debian`.

Once you login please run the tool `first-boot` in your terminal, it'll setup the system for seamless performance and finalize the installation.

## Live USB

This will be made available soon.


## Contribute

If you wish to contribute, for now please consider opening pull requests or issues.

Optionally, you can message me at cgoesc2@wgu.edu