extends Node

const MENU: String = "res://Scenes/menu.tscn"
const GAME: String = "res://Scenes/Game.tscn"
const WINLOSE: String = "res://Scenes/WinLose.tscn"
const ENEMY: PackedScene = preload("res://Scenes/Enemy.tscn")
const SNOWBALL: PackedScene = preload("res://Scenes/Snowball.tscn")
const FLAMETHROWER: PackedScene = preload("res://Scenes/flamethrower.tscn")

const grid_size: int = 16
var win: bool = false
