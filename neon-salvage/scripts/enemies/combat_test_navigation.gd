@tool
extends NavigationRegion2D

@export_tool_button("Build Combat Navigation")
var build_action: Callable:
	get:
		return build_navigation


func build_navigation() -> void:
	var polygon := NavigationPolygon.new()

	polygon.agent_radius = 30.0

	polygon.parsed_geometry_type = (
		NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	)

	polygon.parsed_collision_mask = 1

	polygon.source_geometry_mode = (
		NavigationPolygon.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	)

	polygon.source_geometry_group_name = &"navigation_blockers"

	polygon.add_outline(PackedVector2Array([
		Vector2(-600, -400),
		Vector2(600, -400),
		Vector2(600, 400),
		Vector2(-600, 400),
	]))

	navigation_polygon = polygon
	bake_navigation_polygon()
