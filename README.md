Auto PuG Manager (APM)
Auto PuG Manager is a comprehensive raid-leading and Pick-up Group (PuG) assembly addon for World of Warcraft 3.3.5a. Designed with custom realms (like Ascension WoW) in mind, APM fully automates chat recruitment, whisper parsing, group invites, and role tracking.

🚀 Installation
Download the latest AutoPuGManager folder.

Extract the folder into your World of Warcraft directory: World of Warcraft\Interface\AddOns\AutoPuGManager.

Launch the game and ensure "Auto PuG Manager" is enabled in your AddOns list at the character selection screen.

⌨️ Slash Commands
/apm — Opens or closes the main configuration interface.

✨ Core Features
Automated Invites: Automatically invites players who whisper you with matching role keywords, provided the raid has room for that specific role.

Dynamic Chat Advertisement: Spams your customized recruitment message to a designated channel on a set timer.

Live Roster Tracking: A movable, on-screen tracker that actively monitors the roles, custom flags, and specific level conditions of your current raid members.

Scrollable Overflow Queue: Players who whisper you when their role is full, or who lack a mandatory requirement, are safely placed into a graphical queue. You can manually invite them later with a single click.

Custom Flag Requirements: Track up to two unique conditions (e.g., "Aura of Experience", "Heirlooms"). You can set these to be purely informational, or strictly mandatory for an auto-invite.

Manual Assignment Popups: If a player joins the raid manually (e.g., a guild invite), APM detects the new member and prompts you with a quick popup to assign their role so the tracker remains perfectly accurate.

⚙️ Configuration Guide
Type /apm in-game to access the configuration panel.

Role Limits
Define exactly how many players of each role you want in your group.

Tank / Heal / mDPS / rDPS: Set specific limits for each.

Any DPS: If you enter a number into "Any DPS", it will automatically override and disable the specific Melee (mDPS) and Ranged (rDPS) limits, treating all damage dealers equally.

1st Flag: Limit the maximum number of players the tracker will count for your primary custom flag (e.g., 3 players with an Aura).

Tracker Options
Controls the movable on-screen HUD.

Show Tracker: Toggles the HUD on or off.

Track 1st Flag: Includes your custom 1st Flag in the tracker count.

List 1st Flag Names: Adds a second line to the tracker listing the names of everyone in the raid currently holding the 1st Flag.

List Lvl Names: Adds a third line to the tracker listing players who meet a specific level condition.

Lvl Cond: The mathematical condition for the level tracker. Supports standard operators (e.g., >50, <20, =60, >=10).

Keywords (Comma Separated)
This is the dictionary APM uses to read incoming whispers. You can map multiple words to a single role by separating them with commas (no spaces).

Example Tank: tank,prot,bear,blood

Example 1st Flag: aura,aoe,exp

Need Checkboxes: Next to the 1st and 2nd Flag keyword boxes are "Need" checkboxes. If checked, a player must include a matching flag keyword in their whisper to get an auto-invite. If they don't, they are pushed to the overflow queue.

Chat Spam Configuration
Automates your recruitment message.

Spam Text: The exact message sent to chat.

Dynamic Variable: Include the tag %STATS% anywhere in your message. APM will replace %STATS% with your real-time group needs right before sending the message (e.g., "LFM Raid! Tanks: 1/2 - Heal: 1/2 - DPS: 8/11 whisper role").

Channel: Type the name of the channel (e.g., world, LookingForGroup) or the channel number (e.g., 4).

Interval (Secs): How often the message is sent. Set this to 0 to completely disable chat spamming.

Whisper / Invite Options
Manual Invite Whisper Phrase: The exact text APM will whisper to a queued player when you click the "Invite" button next to their name in the Overflow Queue.

Auto-Response: The whisper APM sends to a player when they are placed into the overflow queue (e.g., "Role full, you are in the queue!").

Queue Expire (Mins): Automatically deletes players from the overflow queue if they have been waiting longer than this duration.

🛠️ Usage Tips & Tricks
Starting & Stopping: The addon remains completely dormant until you click the "Start APM" button at the bottom of the UI. Once started, the tracker will appear, and chat spam will begin. Clicking "Stop APM" pauses the spam, hides the tracker, and clears out any pending manual assignments.

Auto-Pause: If your group fills up (all role limits are met), APM will intelligently pause the chat spam to prevent you from getting muted or annoying the server. It continues to catch incoming whispers into the overflow queue. If someone leaves, a popup will ask if you want to resume spamming.

Reset My Role: Click the "Reset My Role" button in the bottom left of the configuration window if you need to change your own role. The assignment popup will appear, allowing you to correctly catalog yourself for the tracker.

Opaque UI Background: If you dislike the default transparent Blizzard dialog boxes, check the "Opaque UI Background" box at the bottom right. This instantly reskins every APM window to a solid, highly visible black background.
