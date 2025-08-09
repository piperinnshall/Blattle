# Cleanup Pattern

```gd
var spawned_enemies: Array = []

func spawn_enemy():
    var enemy = enemy_scene.instantiate()
    add_child(enemy)  # makes it child of this scene
    spawned_enemies.append(enemy)
    # Optional: connect signals in a way that cleans up automatically
    enemy.connect("enemy_dead", Callable(self, "_on_enemy_dead"))

func _on_enemy_dead(enemy):
    if enemy in spawned_enemies:
        spawned_enemies.erase(enemy)
    # enemy can free itself or you can:
    enemy.queue_free()

func _exit_tree():
    # defensive cleanup in case something lingered
    for e in spawned_enemies:
        if is_instance_valid(e):
            e.queue_free()
    spawned_enemies.clear()

```

