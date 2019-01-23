Flatkvm is a tool to easily run [flatpak](https://flatpak.org/) apps isolated inside a VM, using QEMU/KVM.

This repository contains a script (**build.sh**) and some support files to build an Alpine Linux based template. You'll need to add the **flatkvm-agent** binary to **files/** before executing the script.

**WARNING**: The script doesn't do any kind of error checking, and to make things worse, it needs to be run as root. Please use it with care, and execute it only on a dedicated VM.
