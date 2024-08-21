# Auto run on every keyboard

Want to run KMonad on every keyboard which is or gets connected?
Even during initramfs step to decrypt drives?

Then this is for you!

## Install

```bash
install -Dm644 global-kmonad@.service -t /etc/systemd/system/
install -Dm644 70-kmonad.rules -t /etc/udev/rules.d/
install -Dm644 sd-kmonad -t /etc/initcpio/install/
```

### Initramfs using `mkinitcpio` with `systemd` base

Add `sd-kmonad` to `/etc/mkinitcpio.conf` under hooks
prior to the `sd-encrypt` hook.

## Author

Me, or more specifically [Joschua Kesper](https://github.com/jokesper)
