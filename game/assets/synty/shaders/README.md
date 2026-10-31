# Synty materials for Godot 4.5

Open **preview.tscn** and run the current scene (F6) to see the palm, grass-covered rock,
animated water, clouds, refractive crystal, soft-particle card, and both sail shader variants.

Pirate Realm's `Fabric` and `Alpha_DoubleSided` graphs are translated as well. The 14 animated
`ShipSails_*.material` resources use fabric wind, edge normals, symbol overlays, back-face lighting,
and cloth transmission. The 14 `Static/ShipSails_Static_*.material` resources use the two-sided
alpha-cutout shader. Their original resources are backed up before replacement.

Sail base tint defaults to neutral white so the source texture is unchanged. To recolor one sail,
select its material and edit **Shader Parameters > Base > Color Tint**. **Symbol Color Tint** changes
only the overlaid emblem. Duplicate the material first when only one placed sail should change.
The existing material paths have already been updated: 60 foliage materials and 39 PolygonShader
materials from Tropical Jungle and Pirate Realm. Existing prefab references keep working.
121 embedded fallback materials in Pirate Realm's extracted meshes were also replaced using
unambiguous material references from the original Unity prefabs. Mesh geometry was not edited.

If Godot was open during conversion, reopen the project to discard cached material resources.
You do not need to reimport the Unity packages.

## Editing

Select an existing `.material` in the FileSystem dock and expand **Shader Parameters**.
Parameters are grouped into Leaves, Trunk, Wind, Triplanar, Overlay, Snow, and related sections.
Unity property names are preserved, including their leading underscores.

- **Palms:** use Leaf Texture for the leaf image and Trunk Texture for the bark image.
  The mesh's blue vertex-color channel selects leaves when greater than 0.5 and trunk otherwise.
  Alpha Clip Threshold controls texture cutouts; leaf alpha cannot erase the trunk.
- **Rocks:** enable Triplanar Texture and set its Top, Side, and Bottom textures.
  Top To Side Difference and Fade control coverage. Grass on Rock_Grass_Triplanar_01 is its
  triplanar top texture, not its optional Overlay texture.
- Make the material unique first if you want to change only one object.
- An object's separate Material Override can supersede the imported material. Clear an obsolete
  override or assign the converted material there if an individual object still looks different.

`foliage.gdshader` translates the original surface and vertex graph: bark/leaf selection, textures,
tiling, cutouts, colors/noise, normal maps, AO, metallic/smoothness, frosting, emission/pulse, and wind.
`polygon.gdshader` translates the original opaque PolygonShader surface graph and its triplanar
subgraphs: base, overlay/UV channel, top/side/bottom projection and normals, snow, AO, and emission.
Both account for Unity/Godot coordinate and UV conventions and Godot's compressed normal maps.

This is not a universal Shader Graph converter. Sky and the separate transparent PolygonShader
graph remain outside this port. Water, clouds, particles, and crystal use the hand-translated
shaders in this folder and configured materials under `materials/`. Noise uses a three-octave value-noise
implementation; its exact pattern and engine lighting can differ from Unity. Unity's global weather
controller and LOD crossfade script integration are not included. Weather inputs are exposed as
per-material parameters; Godot owns LOD handling. Extra overlay UV channels require mesh UV3/UV4 data.

## Maintenance and verification

The Unidot material adapter now selects these shaders when importing the matching material
properties. Its existing Standard/Generic material conversion remains in place.

From the project root (replace `godot` with your executable):

```text
python tools/port_synty_graphs.py
godot --headless --path . --log-file .godot/synty-test.log --script addons/unidot_importer/test/synty_material_test.gd
godot --path . --log-file .godot/synty-pixels.log --script tools/test_synty_pixels.gd --quit-after 300
godot --headless --path . --log-file .godot/synty-audit.log --script tools/audit_synty_materials.gd --quit-after 10
godot --headless --path . --log-file .godot/synty-extra.log --script tools/apply_extra_synty_shaders.gd -- --apply
godot --headless --path . --log-file .godot/synty-sails.log --script tools/apply_synty_sails.gd -- --apply
```

The compiler reads the original `.shadergraph.failed_import` files and generates the two shaders
and their parameter schemas. Unsupported nodes fail explicitly. It is scoped to these graph versions.
The original shader files remain untouched. `tools/synty_source_materials.json` preserves the relevant
source material settings; `tools/synty_mesh_assignments.json` records mesh-assignment evidence.

GPU checks verify leaf/trunk selection, leaf-only transparency, and triplanar top/side/bottom selection.
The resource audit verifies material types, texture references, backups, preserved resource UIDs, and
representative prefab material assignments. The preview was rendered with Forward+ on Godot 4.5.1.
This environment emits certificate-store and shader-cache write warnings; the rendering tests pass.
One headless test run also crashed during engine shutdown after its assertions passed; the repeat run
exited normally. The graphical Forward+ tests completed successfully.

Reapplying source settings overwrites manual edits to the converted materials:

```text
godot --headless --path . --log-file .godot/synty-apply.log --script tools/apply_synty_materials.gd -- --apply
godot --headless --path . --log-file .godot/synty-mesh.log --script tools/apply_synty_mesh_assignments.gd -- --apply
```

The second command can repair old mesh fallbacks again if an FBX reimport replaces them.
It skips materials that are already externally assigned. Backups are never overwritten by these tools.

## Undo

Original material and mesh files are in `synty_material_backup/` at the project root, excluded from
Godot import with `.gdignore`. To restore them (this also replaces any later edits to those files):

```text
godot --headless --path . --log-file .godot/synty-restore.log --script tools/restore_synty_materials.gd -- --restore
```

Then reopen the project. The importer code and generated shaders remain available for future imports.
