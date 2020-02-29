# Anti-Noclip Field
This tool allows you to create anti-noclip fields in [Garry's Mod][].
Players in these fields are unable to noclip.

# Workshop Installation
The Anti-Noclip Field is available on the Steam Workshop! Go to [its Workshop page][workshop] and press `Subscribe`, and it will automatically appear in Garry's Mod.

## Requirements
1. Up to date [Garry's Mod][] Server/Client.

## Recommended addons
1. [Wiremod][] for Wiremod functionalities.
1. [PermaProps][] for saving the fields permanently.

## How to use
You spawn the an Anti-Noclip Field with the toolgun. You find this tool in the 'Construction' section of your tool menu.

The settings in the toolgun have tooltips, mouse over them to see them.
They may help you if you need to know something about an option.

# Features
- Blocks players noclip inside an anti-noclip area.
- Built-in admin checks to prevent abuse.
- Extended features for admins.
- [CPPI][] Support
- [PermaProps][] Support

If you an admin you can also disallow these actions:
- Spawning objects
- Tool use
- Entity drive
- Changing entity properties
- Using physgun, gravitygun
- Entering vehicles
- Picking up props
- Killing or damaging themselves
- Killing or demaging others or props
- Options to enable protection from outside

## Additional Notes
If you try to disallow the above options as a non-admin it wont work.
Bypassing by duping, won't work either. (Please report exploits if you find them)

# ConVars and ConCommands

- sv_anti_noclip_field_adminonly 0/1 (Default: 0)
  - Disables this tool for non-admins.

- sv_anti_noclip_field_maxsize 128-16384 (Default: 512)
  - Change the max size of the fields, it will also clamp already placed ones.

- sv_anti_noclip_field_freeforall 0/1 (Default: 0)
  - Allows admin only features of the tool for everyone.

- sv_anti_noclip_field_blocksuperadmin 0/1 (Default: 0)
  - Allows superadmins to be blocked.

- sv_anti_noclip_field_rechecktime 0.01-5 (Default: 0.25)
  - Changes the interval of how often the field checks for players.
  - Increase for better server performance. Higher values are less accurate.


# Credits
- Code: Grocel

# License
<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons Attribution-NonCommercial 4.0 International License</a>.

[Garry's Mod]: <http://garrysmod.com/>
[Wiremod]: <https://github.com/wiremod/wire>
[PermaProps]: <https://github.com/MalboroDEV/PermaProps>
[workshop]: <https://steamcommunity.com/sharedfiles/filedetails/?id=165559580>

[CPPI]: <http://ulyssesmod.net/archive/CPPI_v1-3.pdf>
