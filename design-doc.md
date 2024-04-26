## General notes
- The entire plugin should be typed.
- There should be an object that each represent a file that's being watched.
- You should be able to index the objects with absolute file path.
- Only one array should hold all the objects no other global variable should
  hold the objects.
- server.lua can stay, it takes a file and a callback and call that callback
  with the object that watches that file.
- fetch.lua can stay, it just download some binaries.
- events/ and commands.lua should be rewritten.

## New architecture
- `server/`
  - `server/factory.lua` makes servers, which are objects each representing a
    file or a buffer that a server is watching.
  - `server/inventory.lua` store servers. It make sure that two server cannot
    watch the same file.
  - `server/init.lua` (maybe rename) contains the class definition and all its
    methods. The methods handles event specific logic and encapsulate the
    textual interface.
  - The outside world calls functions in `inventory.lua` which will call
    `factory.lua` if needed to ensure that servers are only managed in
    `inventory.lua`.
- `commands.lua` does not do anything except register user command and map them
  to functions. It should not contain any logic.
- `fetch.lua` do everything that needs to be done in terms of managing binaries.
- `events/`
  - `events/editor.lua` handles editor initiated events. It register listeners
    through autocmds.
  - `events/server.lua` handles server initiated events. It register listeners
    by listening on the server's output.
