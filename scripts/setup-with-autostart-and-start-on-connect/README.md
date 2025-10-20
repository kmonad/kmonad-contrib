# User-Local Setup With Systemd-Governed Start of KMonad

This small guide will show how one can set up KMonad in a way that:

  * almost all configuration resides in $XDG_CONFIG_HOME
  * KMonad is started and restarted for all (preconfigured) keyboards that are
    connected to the computer
  * no custom scripts and runtime logic is required, thanks to systemd

The benefit of this setup is that now almost all configuration can be edited
without root permissions. Furthermore, thanks to residing in $XDG_CONFIG_HOME,
almost all configuration files can be managed using dotfiles managment systems,
e.g. [chezmoi](https://www.chezmoi.io/) so they become easily available on
multiple systems like a second tower PC.

In order to achive this, this guide will show how to:

  1. enable reading of `/dev/uinput` for normal users; this is the only mandatory
     step requiring root access
  2. make bluetooth keyboards available in /dev/input/by-id/ so they appear at a
     predictable location; this too would require root access
  3. configure KMonad
  4. set up systemd integration that starts KMonad if a new keyboard is connected.

Each of these steps is covered in its own section.

## Making Available `/dev/uinput` to Non-Root Users

It is very convenient to be able to start KMonad with normal user privileges,
i.e. without having to prefix it with `sudo`. In order to do so `/dev/uinput`
needs to be available to everyone who wants to use KMonad.

To make this possible, first a new user group needs to be created. For it, the
self-suggesting name `uinput` is chosen. The group can be created using the command

```bash
sudo groupadd --system  uinput
```

Since systemd 258 it is required that the group is a system group, hence the flag.

Now every user who wants to be able to use KMonad needs to be added to that
group. One's own user can be added using

```bash
sudo usermod -aG input,uinput $USER
```

Note that this change takes effect only at the next login.

Finally, an udev rule needs to be created that grants everyone in the group
`uinput` read-access to `/dev/uinput`. For this, the following file content
needs to be added to `/lib/udev/rules.d/99-uinput.rules`:

```udev
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
```

The easiest way to make this change take effect is to reboot the system.
However, to avoid that the following snippets might be helpful:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger --name-match=uinput
```

With that, everything is set up to allow normal users to run KMonad for their
keyboards.


## Make Bluetooth Keyboards Available

Some Bluetooth keyboards are available neither under `/dev/input/by-path` nor
under `/dev/input/by-id` by themselfs. One example is the Cherry MX 3.0S BT,
which is available only at `/dev/input/eventN` with `N` being a number that
changes on every reconnect.

An elegant and convenient way to make these keyboards available to KMonad is to
create another udev rule that puts a symlink to the event file to
`/dev/input/by-id/cherry-mx-bt-kbd`. The author's udev rule for the
aforementioned keyboard is:

```udev
# udev rule for Bluetooth keyboard
# Located at /lib/udev/rules.d/99-cherry-mx-bt.rules

# these rules are specific for the keyboard at hand (vendor: 0687, product: 0004)
SUBSYSTEM=="input", KERNEL=="event*", ATTRS{id/bustype}=="0005", \
  ATTRS{id/vendor}=="0687", ATTRS{id/product}=="0004", \
    ENV{ID_INPUT_KEYBOARD}=="1", \
      SYMLINK+="input/by-id/cherry-mx-bt-kbd"
```

How to write udev rules is described
[here](https://michaelbergeron.com/blog/quick-guide-writing-udev-rules) and
[here](https://wiki.archlinux.org/title/Udev) in detail. As a small pointer,
one needs to get the required information, e.g. vendor ID, product ID and bus
ID, using the command

```
udevadm info --query=all --name=/dev/input/event<CORRECT_ID>
```

where `<CORRECT_ID>` is replaced by the correct event ID of the keyboard.
