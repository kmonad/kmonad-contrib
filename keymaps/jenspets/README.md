# Keybard layout

This keyboard layout is based on the same layout I use for other keyboards. It is based on a 34-key layout using several layers and homerow modifiers. 

I use Colemak-DH ISO layout for the base layer, and with the extra ISO-key next to left shift for "z". 

# Layers

The layers are designed to work with the machine set up to use the US international keymap. The reason for this, is that all OSes has this keymap, and it contains all special characters I need with the AltGr key. 

## Colemak
This is the base layer, based on the Colemak Mod-DH ISO with the angle mod. 

## Lower 

The lower layer contains all special characters. In addition it changes the backspace to del, and contains a caps-lock.

## Raise 

The raise layer contains all the numbers, the F-keys, home/end, page up/down, insert, and printscreen (sysreq). 

It should be noted that the numbers are laid out according to Benford's law, assuming that with the exception of the first digit, which follow a logarithmic distribution, while all other digits are uniformly distrirbuted. The most used numbers are placed in the most comfortable finger positions. I addition, the numbers are split between odd numbers on the left hand and even numbers on the right hand. 

## Adjust 

The adjust layer has various adjustments. It is not used for this layout, as much of the adjustments are not needed or not available on the laptop keyboard. However, for other keyboards, I use this for controlling light effects, Bluetooth connections, solenoid settings, and so on. 

## Audio

The audio layer contains volume and playback controls.

## Navigation

The navigation layer contains arrow keys, tab, and home/end/page up/page down cluster. There is also modifier keys for jumping words or paragraphs, marking text, etc. My other keyboards has mouse navigation and keys on this layer, but I have not added this here. 

## Numeric

The numeric layer contains a numpad, numpad operator keys, and numlock. In additions there are navigation keys, tab, and backspace/delete to make it easier to navigate in spreadsheets or other places where I have to type a lot of numbers in various fields.

# Keyboards 

Only one keyboard is configured right now, as my other keyboards has all functionaliy configured. 

## Zbook ISO

This is a laptop keyboard used with the HP Zbook laptop with an ISO keyboard. It does have a numpad, but I have not configured this.

# TODO

There are still a few things that I want to see if I can implement in the keymap:
- Caps word: Pressing both shifts will capitalize the next word.
- Mouse keys and movements.
- Add the key nuhs to keymap. (Non-US Hash) Currently, only nubs (Non-US Backslash) seems to be defined in the source.

Some is only keymap tweask, but others might require a patch to KMonad.

# Origins 

The origin of this layout is from the keymap I use for my QMK and ZMK keyboards. The sources for those can be found here:
- https://github.com/jenspets/qmk_userspace
- https://github.com/jenspets/zmk-config

