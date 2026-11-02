extends SceneTree
## Headless gameplay smoke test: plays the whole Stage 1 loop through the real
## game script and fails (exit 1) if anything is off.
## Run: godot --headless --path . --script res://tests/smoke_test.gd

var failures := 0

func check(cond: bool, msg: String) -> void:
	if cond:
		print("PASS  ", msg)
	else:
		print("FAIL  ", msg)
		failures += 1

func _initialize() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	check(main.nest_completion() == 0.0, "nest starts at 0%")
	check(not main.scent_unlocked, "scent starts locked")

	# gather everything
	for r in main.resources:
		main.player.position = r["pos"]
		for i in 4:
			main.interact()
	check(main.total_gathered == 27, "gathered 27 items from 9 nodes (got %d)" % main.total_gathered)

	# environmental respawn: depleted nodes stay empty ~1 minute, then regrow
	var all_empty := true
	for r in main.resources:
		if r["charges"] != 0: all_empty = false
	check(all_empty, "all gathered nodes are depleted")
	main._process(30.0)
	check(main.resources[0]["charges"] == 0, "trees still regrowing after 30s")
	main._process(31.0)
	var all_back := true
	for r in main.resources:
		if r["charges"] != 3: all_back = false
	check(all_back, "all nodes respawned after ~1 minute")

	# interacting far from anything does nothing
	main.player.position = Vector2(700, 330)
	var before: int = main.total_gathered
	main.interact()
	check(main.total_gathered == before, "no interaction at unrealistic distance")

	# deposit at nest
	main.player.position = main.nest_pos
	main.interact()
	check(main.nest_completion() == 100.0, "nest reaches 100%% (got %f)" % main.nest_completion())
	check(main.inventory["wood"] >= 0 and main.inventory["grass"] >= 0 and main.inventory["leaves"] >= 0, "inventory never negative")
	main._process(0.1)
	check(main.scent_unlocked, "scent unlocked at threshold")
	check(main.happiness() > 85.0, "happiness reflects nest (%f)" % main.happiness())

	# posts: mark each, then confirm duplicates are not double-counted
	for p in main.posts:
		main.player.position = p["pos"]
		main.interact()
		main.interact()
	check(main.posts_marked() == 4, "4 posts marked exactly once")

	# crop
	main.player.position = main.plot_rect.get_center()
	main.interact()
	check(main.crop_state == main.CROP_GROWING, "crop planted")
	main.interact()
	check(main.crop_state == main.CROP_GROWING and not main.crop_harvested, "cannot harvest before regrowth")
	main._process(100.0)
	check(main.crop_state == main.CROP_READY, "crop ready after growth time")
	main.interact()
	check(main.crop_harvested, "crop harvested")

	main._process(0.1)
	check(main.won, "all objectives complete -> win")

	print("RESULT: ", "ALL PASSED" if failures == 0 else "%d FAILED" % failures)
	quit(0 if failures == 0 else 1)
