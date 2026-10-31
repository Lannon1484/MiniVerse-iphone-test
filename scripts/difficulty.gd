extends RefCounted
# Device-local progression; each completed round unlocks one difficulty step.
const SAVE := "user://miniverse_difficulty.cfg"
static var retry_levels: Dictionary = {}
static func set_retry_level(game_id: String, retry_level: int) -> void:
    retry_levels[game_id] = retry_level
static func clear_retry_level(game_id: String) -> void:
    retry_levels.erase(game_id)
static func level(game_id: String) -> int:
    if retry_levels.has(game_id):
        return int(retry_levels[game_id])
    var cfg := ConfigFile.new()
    if cfg.load(SAVE) != OK:
        return 1
    return clampi(int(cfg.get_value("completed", game_id, 0)) + 1, 1, 20)
static func complete(game_id: String) -> void:
    # Replay does not erase progress or re-unlock levels already completed.
    if retry_levels.has(game_id):
        retry_levels.erase(game_id)
        return
    var cfg := ConfigFile.new()
    cfg.load(SAVE)
    var count: int = int(cfg.get_value("completed", game_id, 0))
    cfg.set_value("completed", game_id, mini(count + 1, 19))
    cfg.save(SAVE)


static func reset_game(game_id: String) -> void:
    retry_levels.erase(game_id)
    var cfg := ConfigFile.new()
    cfg.load(SAVE)
    cfg.set_value("completed", game_id, 0)
    cfg.save(SAVE)

static func reset_all() -> void:
    retry_levels.clear()
    var cfg := ConfigFile.new()
    cfg.load(SAVE)
    if cfg.has_section("completed"):
        cfg.erase_section("completed")
    cfg.save(SAVE)
