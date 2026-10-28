# Saltmire Save Lite

One-line save/load for Godot 4. Free, MIT.

```gdscript
Save.write("slot1", {"hp": 80, "level": 3})
var d = Save.read("slot1")   # null if it doesn't exist
```

API: `write` / `read` / `has` / `erase` / `list_slots` / `autosave` / `stats`.
Saves live in `user://saltmire_saves/`.

Enable via **Project Settings → Plugins → Saltmire Save Lite** (registers the
`Save` autoload).

Need encryption, backup + corruption recovery, schema migration and gzip
compression? → **Saltmire Save PRO ($4.99)**: https://saltmire.itch.io/saltmire-save
