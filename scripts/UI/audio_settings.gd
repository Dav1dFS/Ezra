extends VBoxContainer

@onready var master_row = $TopGroup/MasterRow
@onready var sfx_row = $TopGroup/SFXRow
@onready var music_row = $TopGroup/MusicRow
@onready var buttons_row = $BottomGroup/ResetApplyRow

const DEFAULT_MASTER = 100.0
const DEFAULT_SFX = 100.0
const DEFAULT_MUSIC = 100.0

var _applied_master := DEFAULT_MASTER
var _applied_sfx := DEFAULT_SFX
var _applied_music := DEFAULT_MUSIC

var _pending_master := DEFAULT_MASTER
var _pending_sfx := DEFAULT_SFX
var _pending_music := DEFAULT_MUSIC

func _ready():
	master_row.volume_changed.connect(_on_master_volume_changed)

func _on_master_volume_changed(value: float):
	_pending_master = value

func _on_sfx_volume_changed(value: float):
	_pending_sfx = value

func _on_music_volume_changed(value: float):
	_pending_music = value

func _on_apply_pressed():
	_apply_settings(_pending_master, _pending_sfx, _pending_music)

func _on_reset_pressed():
	master_row.set_value(DEFAULT_MASTER)
	sfx_row.set_value(DEFAULT_SFX)
	music_row.set_value(DEFAULT_MUSIC)

	_apply_settings(DEFAULT_MASTER, DEFAULT_SFX, DEFAULT_MUSIC)

func _apply_settings(master: float, sfx: float, music: float):
	_set_bus_volume("Master", master)
	_set_bus_volume("SFX", sfx)
	_set_bus_volume("Music", music)

	_applied_master = master
	_applied_sfx = sfx
	_applied_music = music

	_pending_master = master
	_pending_sfx = sfx
	_pending_music = music

func _set_bus_volume(bus_name: String, value: float):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	var db = percent_to_db(value)
	AudioServer.set_bus_volume_db(bus_idx, db)
	AudioServer.set_bus_mute(bus_idx, value <= 0.0)

func percent_to_db(percent: float) -> float:
	if percent <= 0.0:
		return -80.0
	return 20.0 * log(percent / 100.0) / log(10.0)
