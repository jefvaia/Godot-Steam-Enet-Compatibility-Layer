extends Node

func create_lobby(args: Array[String]) -> void:
	Static.networker.create_lobby()
	Static.console.print_console("Creating a lobby.\n")
	Node3D

func join_lobby(args: Array[String]) -> void:
	Static.networker.join_lobby(args[0])
	Static.console.print_console("Joining a lobby.\n")

func leave_lobby(args: Array[String]) -> void:
	Static.networker.leave_lobby()
	Static.console.print_console("Leaving lobby.\n")

func dump(args: Array[String]) -> void:
	if args[0] == "lobby":
		printt(Static.networker.lobby_identifier, Static.networker.my_id, Static.networker.host_id, Static.networker.get_players())
	Static.console.print_console("Dumped.\n")

func test(args: Array[String]) -> void:
	if args[0] == "networking":
		Static.networker.queue_message(Static.network_test)
	if args[0] == "object":
		if args[1] == "create":
			Static.networker.queue_message(Static.spawn_test)
		if args[1] == "edit":
			Static.networker.queue_message(Static.edit_test)
		if args[1] == "destroy":
			Static.networker.queue_message(Static.destroy_test)
		if args[1] == "function":
			Static.networker.queue_message(Static.function_test)
	Static.console.print_console("Ran test.\n")
