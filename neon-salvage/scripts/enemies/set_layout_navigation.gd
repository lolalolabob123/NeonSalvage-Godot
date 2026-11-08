@tool
extends EditorScript

func _run() -> void:
	var scene := EditorInterface.get_edited_scene_root()
	
	if scene == null or scene.name != "Blacksite7_LayoutTest":
		push_error("Open Blacksite7_LayoutTest before running this script.")
		return
	
	var region := scene.get_node_or_null(
		"EnemyNavigation"
	) as NavigationRegion2D
	
	if region == null or region.navigation_polygon == null:
		push_error("EnemyNavigation needs a NavigationPolygon.")
		return
	
	# Preserve the configured baking system settings in a seperate resource.
	var polygon := region.navigation_polygon.duplicate() as NavigationPolygon
	polygon.clear_outlines()
	polygon.clear_outlines()

	polygon.add_outline(PackedVector2Array([
		Vector2(-400, -300),
		Vector2(400, -300),
		Vector2(400, -80),
		Vector2(912, -80),
		Vector2(912, -300),
		Vector2(1712, -300),
		Vector2(1712, -80),
		Vector2(2224, -80),
		Vector2(2224, -300),
		Vector2(3024, -300),
		Vector2(3024, 300),
		Vector2(2224, 300),
		Vector2(2224, 80),
		Vector2(1712, 80),
		Vector2(1712, 300),
		Vector2(912, 300),
		Vector2(912, 80),
		Vector2(400, 80),
		Vector2(400, 300),
		Vector2(-400, 300),
	]))
	
	region.navigation_polygon = polygon
	EditorInterface.mark_scene_as_unsaved()
