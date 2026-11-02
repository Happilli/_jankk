# jankk
https://github.com/user-attachments/assets/3bb139e8-0470-4de8-90d2-8cc35d136bf8

> **Note:** UI will get massive changes and overhaul so it wont be same as the preview shows.

A fast, controller-style launcher and frontend for Game Boy Advance games(!only), built with Qt Quick and [mGBA](https://mgba.io/).

## Install

### Arch Linux (AUR)

```bash
(aur-helper) -S jankk # builds from source
(aur-helper) -S jankk-bin # prebuilt binary
```
## Where to put your games

By default jankk looks in:

```
~/Games/encore
```

Or pass any folder as an argument:

```bash
jankk (path to the rom)
```

Put your `.gba` files directly in that folder (subfolders are not scanned):

```
~/Games/encore/
|-- final_fight.gba
|-- images/
```

Notes:

- Only `.gba` files are listed.
- Titles are cleaned up for display: anything in `()` or `[]` is removed, and `Legend of Zelda, The` becomes `The Legend of Zelda`.
- Files with `(MB2GBA)` in the name are skipped.
- Save files are created next to the ROM by mGBA.

## Where to put the art

Create an `images` folder inside your games folder. Each image is named after the ROM's file name (without `.gba`) plus a suffix, as PNG:

Example for `celestial.gba`:

```
~/Games/encore/images/celestial-image.png
```

The name must match the ROM file exactly, including the region tags in brackets. A game without art still shows up, with its title written on the tile.

## Controls

### Launcher

<table>
  <thead>
    <tr>
      <th>Key</th>
      <th>Action</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Left / Right</td>
      <td>Browse games</td>
    </tr>
    <tr>
      <td>Enter</td>
      <td>Launch the selected game</td>
    </tr>
    <tr>
      <td>Type any text</td>
      <td>Search (accent and case insensitive)</td>
    </tr>
    <tr>
      <td>Backspace</td>
      <td>Delete a character</td>
    </tr>
    <tr>
      <td>Esc</td>
      <td>Clear the search</td>
    </tr>
    <tr>
      <td>Down</td>
      <td>Move from the search box to the list</td>
    </tr>
    <tr>
      <td>F11</td>
      <td>Toggle fullscreen</td>
    </tr>
  </tbody>
</table>

### In game

<table>
  <thead>
    <tr>
      <th>Key</th>
      <th>GBA button</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Arrow keys</td>
      <td>D-pad</td>
    </tr>
    <tr>
      <td>A</td>
      <td>A</td>
    </tr>
    <tr>
      <td>B</td>
      <td>B</td>
    </tr>
    <tr>
      <td>X</td>
      <td>L</td>
    </tr>
    <tr>
      <td>Y</td>
      <td>R</td>
    </tr>
    <tr>
      <td>Enter</td>
      <td>Start</td>
    </tr>
    <tr>
      <td>Space</td>
      <td>Select</td>
    </tr>
    <tr>
      <td>Esc</td>
      <td>Back to the launcher</td>
    </tr>
    <tr>
      <td>F11</td>
      <td>Toggle fullscreen</td>
    </tr>
  </tbody>
</table>

> **Note:** jankk is a desktop app, but the in-game controls follow the button names of a real Game Boy Advance (A, B, L, R, Start, Select, D-pad) so they're easy to learn. A, B, Start, Select and the D-pad map to the keys you'd expect. L and R have no obvious keyboard equivalent, so they sit on **X** and **Y**.

## Command line

```bash
jankk --help
jankk --version
jankk [folder]
```


## License

GPL-3.0. See [LICENSE](LICENSE).
