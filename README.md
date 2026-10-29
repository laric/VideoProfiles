# VideoProfiles

A World of Warcraft addon for Retail and WoW Forever that saves your video
settings as named profiles and lets you swap between them.

A profile stores the video CVars listed in `CVars.lua`: display mode and
resolution, frame rate limits, anti-aliasing, the graphics quality presets
(including raid quality) and the advanced settings. CVars the running client
doesn't have are skipped. Profiles are shared by every character on the
account.

## Usage

Type `/vp` or open **Options > AddOns > VideoProfiles**. Select a profile on
the left; the right side shows what differs from your current settings, or
from another profile picked from the **Compare with** list. **Show all**
lists every value in the profile instead, highlighting the ones that
differ. The buttons below the list save, apply, update, rename, delete, export
and import profiles.

**Export** gives a compressed string (about 330 characters) you can copy to
another computer and paste into **Import** there. Every setting is stored with
its CVar name, and unknown names are skipped on import.

| Command | What it does |
| --- | --- |
| `/vp` or `/vp show` | open the profiles in Options > AddOns |
| `/vp save <name>` | save your current video settings as a new profile |
| `/vp update <name>` | overwrite a profile with your current settings |
| `/vp apply <name>` | switch to a profile |
| `/vp applyreload <name>` | switch to a profile and reload the UI at once, handy in macros |
| `/vp diff <name> [> <other>]` | list differences from current settings or another profile |
| `/vp rename <old> > <new>` | rename a profile |
| `/vp delete <name>` | delete a profile |
| `/vp export <name>` | show a profile as a string to copy to another computer |
| `/vp import [string]` | add a profile from an export string, or open a box to paste it into |
| `/vp list` | list your profiles |
| `/vp cvars` | show which video CVars this client supports, with values, in a copy box |
| `/vp help` | list the commands |

Applying a profile is refused in combat. When display CVars such as resolution
or MSAA change, the graphics engine restarts. Afterwards a popup offers to
reload the UI (it can be turned off on the options page), since changing CVars from an addon can taint the default UI.
