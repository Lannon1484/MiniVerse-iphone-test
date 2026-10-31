extends RefCounted
# Device-local progression; each completed round unlocks one difficulty step.
const SAVE := "user://miniverse_difficulty.cfg"
static func level(game_id: String) -> int:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE) != OK:
        return 1
    return clampi(int(cfg.get_value("completed", game_id, 0)) + 1, 1, 20)
static func complete(game_id: String) -> void:
    var cfg := ConfigFile.new()
    cfg.load(SAVE)
    var count: int = int(cfg.get_value("completed", game_id, 0))
    cfg.set_value("completed", game_id, mini(count + 1, 19))
    cfg.save(SAVE)
