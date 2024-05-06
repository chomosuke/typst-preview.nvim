- `server/`
  - `server/factory.lua` makes servers, which are objects each representing a
    file that a server is watching.
  - `server/inventory.lua` store servers and index them by their absolute path.
  - `server/init.lua` contains the class definition and all its methods. The
    methods, it encapsulate event specific logic.
- `commands.lua` register user command and map them to functions. It should not
  contain too much logic.
- `fetch.lua` do everything that needs to be done in terms of managing binaries.
- `events/`
  - `events/editor.lua` handles editor initiated events. It register listeners
    through autocmds on all file with filetype `typst`.
  - `events/server.lua` handles server initiated events. It register listeners
    on all servers.
- All package inside a folder should not be accessed by those outside except for
  `init.lua`.
