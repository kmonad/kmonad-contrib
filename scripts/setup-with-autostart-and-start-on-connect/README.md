# User-Local Setup With Systemd-Governed Start of KMonad

This small guide will show how one can set up KMonad in a way that:

  * almost all configuration resides in $XDG_CONFIG_HOME
  * KMonad is started and restarted for all (preconfigured) keyboards that are
    connected to the computer
  * no custom scripts and runtime logic is required, thanks to systemd

The benefit of this setup is that now almost all configuration can be edited
without root permissions. Furthermore, thanks to residing in $XDG_CONFIG_HOME,
almost all configuration files can be managed using dotfiles managment systems,
e.g. [chezmoi](http://ADD_LINK_HE.RE) so they become easily available on
multiple systems like a second tower PC.

In order to achive this, this guide will show how to:

  1. enable reading of /dev/uinput for normal users; this is the only mandatory
     step requiring root access
  2. make bluetooth keyboards available in /dev/input/by-id/ so they appear at a
     predictable location; this too would require root access
  3. configure KMonad
  4. set up systemd integration that starts KMonad if a new keyboard is connected.

Each of these steps is covered in its own section.
