Dungenerate
===========

1. Getting the engine:

Note: Upon first clone, the game files but not the engine will be grabbed.
The engine is hosted in a separate repository for modularity purposes. 

As is standard for games, everything is statically linked into the engine. While
the majority of the game is written using Lua, the src/cpp folder contains additional
source code which must be compiled into the engine. 

If one desires only to work on the Lua components, avoiding the build dependencies, 
a binary (executable) copy of the engine can be downloaded instead. As long as the 
engine executable exists in the engine/builds/native (or for example the 
engine/builds/android, engine/builds/mingw32 folders), the run.sh script will succeed.

If an engine is not present, the first time build_engine.sh is run, the engine will be 
cloned into this folder via git.
