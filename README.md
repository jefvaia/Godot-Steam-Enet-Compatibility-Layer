# Godot Steam/Enet Compatibility Layer
## About
This is a template for networking with both Enet and Steamworks in Godot.
The project uses Godot 4.3 with [GodotSteam cuctom recompile](https://godotsteam.com/)
## How it works
The scripts in this project are made to be highly moddable. The data sent through the network is based on custom resources from the `structs` folder.
The `networker.gd` script is the base class. in there are all the "normal" functions you should be able to call. Both `steamnetworker.gd` and `lannetworker.gd` change the behaviour of all the functions for their specific needs.
The `singletons/` folder contains some standard scripts for every project like `static.gd`. `util.gd` is the util script to handle some functions you might also wanna use, even without the networking.
For easy debugging, I also put a `console.gd` and `commands.gd` in the project so you can test features without a functional gui.
The naming scheme also provides some information about functions: if it starts with an underscore, it's an internal function and should not be called from the out-side (unless you know what you are doing). The non-underscore functions are the main functions of the scripts.
### To initiate the networking
The `Util.initialize_networker()` function handles the instancing of `networker.gd`. It's made specifically to check if `Steam` exists and if not, instance the `lannetworker.gd` instead (if exported).
As a piracy counter-measure, you can exclude either `steamnetworker.gd` or `lannetworker.gd`. For example: You might want to use the lan variant to test the game, but not have lan available in the final export for the platform.
### To send data
The game objects you want to be transferred through the network should have scripts. The script should call `Static.networker.queue_message()` to queue a message to every peer in the lobby/server. This function takes a `NetworkMessage` type. When you call this function, the network message you put in as it's parameter get's parsed to a minimal `Array[Dictionary]` through the `Util.resource_to_arr()`. From there, the buffer will be compressed and sent over the network. If you want a network message to be sent reliably, it must be a `NetworkMessageReliable` type, the same goes for `NetworkMessageUnreliable`
The queue gets sent and cleared every frame.
### To receive data
Whenever the networker received a package, it parses the `Array[Dictionary]` back to a `NetworkMessage`and it's sub-type. the packet gets handled by `Util._process_packet()`(mind the underscore, this function is called automatically).
The function checks for authentication packets, ping packets and all subtypes of `NetworkObjectStatusReliable` and `NetworkObjectStatusUneliable`. These packets contain info about the node being influenced, like it's path and type. This function also checks if the node exists at the path and if it's type is correct. From there, it can do 4 things depending on the status type: `NetworkObjectStatus(Un)ReliableSpawn` checks if the node exists and if not, places it at the given path, `NetworkObjectStatus(Un)ReliableEdit` changes the properties of the object given. this function is best usedd in unreliable form for position updating and in reliable form to "correct" the values once in a while. `NetworkObjectStatus(Un)ReliableDestroy` removes an object and `NetworkObjectStatus(Un)ReliableFunction` calls a function on the object with gives parameters (it can call built-in functions without parameters or custom functions with `Array` as parameter type
### To add custom testing
The `commands.gd` script contains functions for testing. These functions get called by typing `<function_name> <arg1> <arg2> ...` in the console. The console calls the functions in `commands.gd` as the structure given. For more information, look at the existing functions in `commands.gd`
##To-Do
Refine documentation and add example project.