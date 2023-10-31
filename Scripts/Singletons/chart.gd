extends Node

# DESCRIPTION:
# Used for chart stuff like loading.
# Also used for getting a charts data.
# DATE CREATED:
# 2022-04-04


# Different note directions.
enum NoteDirs {
	LEFT,
	DOWN,
	UP,
	RIGHT,
}

# Song difficulties.
enum Difficulties {
	EASY,
	NORMAL,
	HARD
}

# The file extensions for each difficulty.
var dif_exts : Array = ["-easy", "", "-hard"]
