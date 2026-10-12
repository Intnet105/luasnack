# LuaSnack

A simple Garry's Mod entity that can run server-side Lua code. Not recommended for use in public servers.

This add-on is available on the Steam Workshop:
https://steamcommunity.com/sharedfiles/filedetails/?id=3346811488

# Instructions

1. Spawn the LuaSnack from the LuaSnack category in Entities.
2. Right-click on the entity using the C-menu (Context Menu)
3. Click on the "Set code..." Context Menu option. 
4. Write your code. Two variables are available:
   
   - `snackpos`: The `Vector` position of the LuaSnack.
   - `eater`: The player who used the LuaSnack.
     
   There is a 511 character limit.
     
5. Click on "Confirm"
6. Press your `+use` (interaction) key on the entity.

## Note

This entity features a string-based blacklist system for non-administrators which is meant to block certain functions, but it is not well-made. Consider replacing it if you plan to use this entity in your own projects.

# ConVars

- `luasnack_admin` *(def. 0)* \- Determines if only administrators can edit a LuaSnack's code.
- `luasnack_errorkill` *(def. 0)* \- Determines if players should die after a Lua error occurs.
