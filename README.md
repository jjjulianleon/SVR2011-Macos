# SvR 2011 on macOS

Play the **WWE SmackDown vs. Raw 2011 PC port** ([KaikoClanworth1/wwe-svr2011-pc](https://github.com/KaikoClanworth1/wwe-svr2011-pc)) on an Apple Silicon Mac, through CrossOver.

One script sets up a CrossOver bottle, downloads the latest release of the port **from its official GitHub page**, installs the game from **your own Xbox 360 disc image**, tunes the settings for Apple Silicon and adds a `SvR 2011` app to Launchpad.

> This repo contains **no game files and no port files**. You need your own Xbox 360 disc of the game, ripped to an `.iso`. Please don't ask for or share disc images.

[Español más abajo](#español)

## Requirements

- Apple Silicon Mac (M1 or newer). D3DMetal, which this uses, does not run on Intel Macs.
- [CrossOver](https://www.codeweavers.com/crossover) 26 or newer in `/Applications`.
- Your WWE SmackDown vs. Raw 2011 **Xbox 360** disc image (`.iso` / `.xiso`, USA or Europe). PS3, Wii, PS2 and PSP versions won't work.
- About 7 GB of free space.

## Install

```bash
git clone https://github.com/jjjulianleon/SVR2011-Macos.git
cd SVR2011-Macos
./install.sh ~/Downloads/your-disc.iso
```

Options:

```text
./install.sh <disc.iso> [game folder] [--bottle NAME] [--enable-mods]
  game folder     where the game goes (default: ~/Games/SvR2011)
  --bottle NAME   CrossOver bottle to create or reuse (default: SVR2011)
  --enable-mods   switch on the bundled superstar and arena mods
```

Then open **SvR 2011** from Launchpad, Spotlight or `~/Applications` and press **Play**. The port's launcher updates itself from new releases.

## What the script does

1. Creates a CrossOver bottle (Windows 10, 64-bit) with `CX_GRAPHICS_BACKEND=d3dmetal` and `WINEMSYNC=1`.
2. Downloads the latest `SvR2011-PC-*.zip` from the port's releases and unpacks it into the game folder.
3. Runs the port's launcher headless (`--install <iso> <folder>`), which reads the disc image and copies the game files out.
4. Writes `svr2011.toml` with settings that keep 60 fps on Apple Silicon (see below), if the folder has none yet.
5. Builds `~/Applications/SvR 2011.app` (`make-app.sh`), with the launcher's own icon.

## Why these settings

- **Direct3D 12 → D3DMetal** is the path that works. The port's native renderer runs on D3D12, and CrossOver's D3DMetal translates it straight to Metal.
- **Vulkan → MoltenVK does not work well.** Older emulated-GPU builds of the port gave a black screen (geometry shaders fail in MoltenVK) or a garbled image (`render_target_path_vulkan=fsi`).
- **60 fps is the ceiling.** The game's simulation is fixed at 60 like the Xbox 360; the port only offers 30 or 60. Higher frame rates would speed the game up.
- Measured on an M1 Pro: about 35-40 fps for the first seconds while shaders build, then a steady 60 fps in menus.

`svr2011.toml` keys set by the installer:

| Key | Value | Why |
|---|---|---|
| `native_aa` / `native_2x_msaa` | `1` / `false` | no supersampling (it rendered 4× the pixels) |
| `native_max_scale` | `2` | caps the render scale in big or fullscreen windows |
| `full_speed` | `true` | extra updates if a frame is late, so the game never runs in slow motion |
| `process_priority` | `1` | the game's threads ahead of background apps |
| `mnk_mode` | `true` | keyboard controls |
| `show_fps` | `true` | FPS counter (F2 toggles it) |

If entrances or matches drop below 60, in the game go to **My WWE → Options → Graphics → Quality**: Shadows & effects **Normal**, Entrance frame rate **30**, and turn off depth of field and motion blur.

## Controls

An Xbox controller works as on the console. The keyboard works too (rebind it in **My WWE → Options → Graphics → CONTROLS**):

| Pad | Key |
|---|---|
| Left stick | W A S D |
| A / B / X / Y | Space / Backspace / L / P |
| LT / RT | Q / E |
| LB / RB | 1 / 3 |
| Right stick | Arrow keys |
| D-pad | Shift + arrows |
| Start / Back | Enter / Tab |

## Recreate the app

```bash
./make-app.sh ~/Games/SvR2011            # [bottle] [destination] are optional
```

## Troubleshooting

- **Logs:** `<game folder>/logs/svr2011_NNN.log` (`fps:` lines every 5 s).
- **Check the graphics API:** the log should say `graphics: Direct3D 12` and `native renderer: D3D12 backend`. If not, check the bottle's `cxbottle.conf` for `"CX_GRAPHICS_BACKEND" = "d3dmetal"`.
- **Reinstall into the same folder:** run `install.sh` again; files already there are kept.
- **Long paths:** the launcher is a Windows program and crashes on paths of 260+ characters. Keep the disc image and the game folder in short paths (e.g. `~/Downloads`, `~/Games`); the script checks this.
- Problems with the game itself go to the [port's GitHub](https://github.com/KaikoClanworth1/wwe-svr2011-pc) or its Discord; problems with the Mac setup go to this repo's issues.

## Status

Tested on an M1 Pro with CrossOver 26 and port v2.0.6. The install from a disc image was tested with a test XDVDFS image built from verified game files, not a real disc rip yet. Reports welcome.

---

## Español

Script para jugar el **port de PC de WWE SmackDown vs. Raw 2011** en un Mac con Apple Silicon usando CrossOver. Crea la bottle, descarga el port **desde su GitHub oficial**, instala el juego desde **tu propia ISO de Xbox 360**, aplica una configuración que mantiene 60 fps y añade la app **SvR 2011** al Launchpad.

Este repo **no incluye archivos del juego ni del port**. Necesitas tu propio disco de Xbox 360 en `.iso`.

**Requisitos:** Mac con Apple Silicon, CrossOver 26 o superior, la ISO de Xbox 360 (USA/Europa) y unos 7 GB libres.

```bash
git clone https://github.com/jjjulianleon/SVR2011-Macos.git
cd SVR2011-Macos
./install.sh ~/Downloads/tu-disco.iso --enable-mods
```

Después abre **SvR 2011** desde el Launchpad y pulsa **Play**.

- **Por qué D3DMetal:** el renderer nativo del port usa Direct3D 12, y D3DMetal lo traduce directo a Metal. El camino Vulkan → MoltenVK daba pantalla negra o imagen rota.
- **Máximo 60 fps:** la simulación del juego va fija a 60, como en la Xbox 360. El port solo ofrece 30 o 60.
- **Si baja de 60** en entradas o combates: *My WWE → Options → Graphics → Quality* → Shadows & effects **Normal**, entradas a **30 fps**, sin depth of field ni motion blur.
- **Teclado:** WASD para moverte, Espacio = A, Backspace = B, L = X, P = Y, Q/E gatillos, Enter = Start. Se cambia en *My WWE → Options → Graphics → CONTROLS*.

## Credits

The port is by [KaikoClanworth1 and contributors](https://github.com/KaikoClanworth1/wwe-svr2011-pc), built with the ReXGlue SDK. This repo only automates the macOS setup. Not affiliated with THQ, Yuke's, WWE, Microsoft or CodeWeavers.
