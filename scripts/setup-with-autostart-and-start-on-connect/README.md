# User-Local Setup With Systemd-Governed Start of KMonad

This small guide will show how one can set up KMonad in a way that:

  * almost all configuration resides in $XDG_CONFIG_HOME
  * KMonad is started for all (preconfigured) keyboards that are
    connected to the computer, each time they are connected
  * no custom scripts and runtime logic is required, thanks to systemd

The benefit of this setup is that now almost all configuration can be edited
without root permissions. Furthermore, thanks to residing in $XDG_CONFIG_HOME,
almost all configuration files can be managed using dotfiles management systems,
e.g. [chezmoi](https://www.chezmoi.io/) so they become easily available on
multiple systems like a second tower PC.

In order to achieve this, this guide will show how to:

  1. enable reading of `/dev/uinput` and `/dev/input/*` for normal users; this
     is the only mandatory step requiring root access
  2. make bluetooth keyboards available in /dev/input/by-id/ so they appear at a
     predictable location; this too would require root access
  3. configure KMonad
  4. set up systemd integration that starts KMonad if a new keyboard is connected.

Each of these steps is covered in its own section.

## Making Available `/dev/uinput` and `/dev/input/*` to Non-Root Users

It is very convenient to be able to start KMonad with normal user privileges,
i.e. without having to prefix it with `sudo`. In order to do so `/dev/uinput`
and all device files in `/dev/input/` need to be available to everyone who
wants to use KMonad.

In order to enable non-root users to read and write to `/dev/uinput`, the users
need to be in the `input` group. How to do will be shown a few paragraphs
below. However, being in the `input` group is not sufficient, since `/dev/uinput`
is by default only readable and writable by root.

To change this, first a new user group needs to be created. For it, the
self-suggesting name `uinput` is chosen. The group can be created using the
command

```bash
sudo groupadd --system  uinput
```

Since systemd 258 it is required that the group is a system group, hence the
flag. Earlier versions of systemd do not require this flag, but it is
recommended to prevent a regreession when upgrading systemd later.

Now every user who wants to be able to use KMonad needs to be added to that
group and to the group `input`. One's own user can be added using

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
under `/dev/input/by-id` by themselves. One example is the Cherry MX 3.0S BT,
which is available only at `/dev/input/eventN` with `N` being a number that
changes on every reconnect.

An elegant and convenient way to make these keyboards available to KMonad is to
create another udev rule that puts a symlink to the event file to
`/dev/input/by-id/cherry-mx-bt-kbd`. An example udev rule for the
aforementioned keyboard would be:

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

## Configure KMonad

In order to use KMonad a configuration file is required. Since KMonad
configuration files list the device they apply to in them, a bit of trickery is
required to be able to reuse the same configuration file for multiple
keyboards.

Consider this example configuration file that maps `esc` to `caps`:

```kmonad
;; $XDG_CONFIG_HOME/kmonad/universal.kbd
(
    defcfg
    input  (device-file "$KMONAD_DEVICE")  ;;
    output (uinput-sink "My KMonad output")
    fallthrough true
)
(defsrc caps)
(deflayer my-layer esc)
```

The important part is how the device file is specified. Instead of hardcoding a
device file, the environment variable `KMONAD_DEVICE` is used. This variable
will be substituted with the correct device when KMonad is started.

## Set Up Systemd Integration

The last step is to set up systemd integration that starts KMonad. For this,
required systemd configuration files need to be created and then enabled.

### Creating Systemd Service and Path Units

This section will show how to create the required systemd configuration files.
All files of this section should go to `$XDG_CONFIG_HOME/systemd/user/`.

For keyboards that are never detached, e.g. built-in laptop keyboards, a
service file is sufficient. An example service file would be:

```systemd
# $XDG_CONFIG_HOME/systemd/user/kmonad-builtin.service
[Unit]
Description=KMonad Service
After=network.target
ConditionPathExists=/dev/input/by-path/platform-i8042-serio-0-event-kbd
ConditionPathExists=%E/kmonad/universal.kbd

[Service]
Type=simple
Environment=KMONAD_DEVICE=/dev/input/by-path/platform-i8042-serio-0-event-kbd
# %E is expanded to $XDG_CONFIG_HOME by systemd
ExecStart=/bin/bash -c 'kmonad <(envsubst < %E/kmonad/universal.kbd)'
Restart=no
RestartPreventExitStatus=1

[Install]
WantedBy=default.target
```

This service file specifies the device file. When started, it will replace
`$KMONAD_DEVICE` in `universal.kbd` with the correct device file and start
KMonad with it. Using appropriate guards, the service is only started if the
keyboard and the configuration file exist.

For keyboards that are frequently detached and reattached, e.g. the external
keyboards in office and at home, a supplementing path unit is recommended. With
it, systemd will automatically start the corresponding systemd service whenever
the keyboard is connected. An example path unit would be:

```systemd
# $XDG_CONFIG_HOME/systemd/user/kmonad-cherry-mx-bt.path
[Unit]
Description=Watch for Cherry MX 3.0S BT Keyboard
Documentation=man:systemd.path(5)

[Path]
PathExists=/dev/input/by-id/cherry-mx-bt-kbd
Unit=kmonad-cherry-mx-bt.service

[Install]
WantedBy=default.target
```

This path unit watches for the existence of a device file (the one created by the
udev rule above) and starts the listed service unit
(`kmonad-cherry-mx-bt.service`) whenever the file appears. This way, KMonad
will be started automatically whenever the keyboard is connected, without
having to resort to custom busy-waiting scripts.

### Enabling Systemd Units

After creating the systemd unit files, they need to be enabled and started.
This can be done using the commands:

```bash
systemctl --user enable --now kmonad-builtin.service
systemctl --user enable --now kmonad-cherry-mx-bt.path
```

For path units, enabling the path unit is sufficient; the corresponding service unit
will be started automatically when the path unit triggers.

### Regarding Systemd Unit Deduplication

The presented setup will result in plenty of systemd unit files that differ in their
input device only. It is tempting to try to deduplicate them using systemd templates.

Deduplication could be done using unit templates like `kmonad@.service` and
`kmonad@.path` and then instantiating them with different instance names for
different keyboards:

```bash
systemctl --user enable kmonad@platform-i8042-serio-0-event-kbd.service
```

In the systemd unit files, the instance name could then be referenced using
`%i` (see [documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#Specifiers) for more of these replacement rules). With that, the service file of the built-in keyboard could look like this:

```systemd
# $XDG_CONFIG_HOME/systemd/user/kmonad@.service
[Unit]
Description=KMonad Service
After=network.target
ConditionPathExists=/dev/input/by-path/%i
ConditionPathExists=%E/kmonad/universal.kbd

[Service]
Type=simple
Environment=KMONAD_DEVICE=/dev/input/by-path/%i
ExecStart=/bin/bash -c 'kmonad <(envsubst < %E/kmonad/universal.kbd)'
Restart=no
RestartPreventExitStatus=1

[Install]
WantedBy=default.target
```

Note the changes in the `ConditionPathExists` and `Environment` lines.

However, this approach has a drawback: The enabled services lose their
self-documenting names. Instead of seeing `kmonad-builtin.service` in the
output of `systemctl --user list-units` and in the folder, one would see a
rather cryptic device ID. Therefore, the author decided against this
deduplication and chose to have separate unit files for each keyboard instead.
