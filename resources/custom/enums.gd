class_name Enums

enum TileType {
	FROM_ATLAS,
	FROM_TERRAIN
}

enum TerrainType {
	PATH,
	CONNECT
}

enum SurfaceType {
	SURFACE = 0, # Tiles that if are on top of (x, y), classify (x, y) as a surface
	BLOCKING = 1, # Tiles that if there are surface tiles under it remove (x, y) from being a surface unless there's a surface above it
	STATIC_ENTITY = 2, # Opposite of blocking

	MAX
}
