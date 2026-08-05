# Auto PuG Manager (APM)

Auto PuG Manager is a comprehensive raid-leading and Pick-up Group (PuG) assembly addon for World of Warcraft 3.3.5a. Designed with custom realms in mind, APM fully automates chat recruitment, whisper parsing, group invites, and real-time role tracking[cite: 17].

---

## 🚀 Installation

1. Download the latest `AutoPuGManager` folder.
2. Extract the folder into your World of Warcraft directory: `World of Warcraft\Interface\AddOns\AutoPuGManager`.
3. Launch the game and ensure "Auto PuG Manager" is enabled in your AddOns list at the character selection screen.

---

## ⌨️ Slash Commands

*   `/apm` — Opens or closes the main configuration interface[cite: 17].
*   `/apm button` — Toggles the visibility of the Minimap button[cite: 17].
*   `/apm t` (or `tank`, `tanks`) — Prints a list of all current Tanks in your chat box[cite: 17].
*   `/apm h` (or `heal`, `healer`, `healers`) — Prints a list of all current Healers in your chat box[cite: 17].
*   `/apm md` (or `mdps`, `melee`) — Prints a list of all current Melee DPS in your chat box[cite: 17].
*   `/apm rd` (or `rdps`, `ranged`) — Prints a list of all current Ranged DPS in your chat box[cite: 17].
*   `/apm d` (or `dps`) — Prints a list of all current DPS (Any, Melee, and Ranged combined) in your chat box[cite: 17].

---

## ✨ Core Features

*   **Automated Invites:** Automatically invites players who whisper you with matching role keywords, preventing over-inviting by reserving spots with a "Pending Invite" engine for 45 seconds[cite: 17].
*   **Smarter Parsing:** The parsing engine actively strips negation phrases (e.g., "no", "without", "lack") from whispers[cite: 17]. If a player whispers "I can heal but have no aura," APM correctly ignores the word "aura" instead of falsely flagging them[cite: 17].
*   **Dynamic Chat Advertisement:** Spams your customized recruitment message to a designated channel on a set timer using the `%STATS%` variable[cite: 17].
*   **Live Roster Tracking:** A movable, on-screen tracker that actively monitors the roles, custom flags, and specific level conditions of your current raid members[cite: 17]. The tracker polls and refreshes group levels automatically every 5 seconds[cite: 17].
*   **Minimap Integration:** A standard, drag-able minimap button allows you to Left-Click to open options, or Right-Click to rapidly Start/Stop the APM engine[cite: 17].
*   **Scrollable Overflow Queue:** Players who whisper you when their role is full, or who lack a mandatory requirement, are safely placed into a graphical queue[cite: 17]. You can manually invite them later with a single click[cite: 17].
*   **Custom Flag Requirements:** Track up to two unique conditions (e.g., "Aura", "Heirlooms"). You can set these to be purely informational, or strictly mandatory for an auto-invite[cite: 17].
*   **Manual Assignment Popups:** If a player joins the raid manually (e.g., a guild invite), APM detects the new member and prompts you with a quick popup to assign their role[cite: 17].

---

## ⚙️ Configuration Guide

Type `/apm` in-game to access the configuration panel[cite: 17].

### Role Limits
Define exactly how many players of each role you want in your group.
*   **Tank / Heal / mDPS / rDPS:** Set specific limits for each[cite: 17].
*   **Any DPS:** If you enter a number into "Any DPS", it will automatically override and disable the specific Melee (mDPS) and Ranged (rDPS) limits, treating all damage dealers equally[cite: 17].
*   **1st Flag:** Limit the maximum number of players the tracker will count for your primary custom flag (e.g., 3 players with an Aura)[cite: 17].

### Tracker Options
Controls the movable on-screen HUD.
*   **Show Tracker:** Toggles the HUD on or off[cite: 17].
*   **Track 1st Flag:** Includes your custom 1st Flag in the tracker numeric count[cite: 17].
*   **List 1st Flag Names:** Adds a second line to the tracker listing the names of everyone in the raid currently holding the 1st Flag[cite: 17].
*   **List Lvl Names:** Adds a third line to the tracker listing players who meet a specific level condition[cite: 17].
*   **Lvl Cond:** The mathematical condition for the level tracker[cite: 17]. Supports standard operators (e.g., `>50`, `<20`, `=60`, `>=10`)[cite: 17]. 

### Keywords (Comma Separated)
This is the dictionary APM uses to read incoming whispers. You can map multiple words to a single role by separating them with commas (no spaces).
*   *Example Tank:* `tank,prot,bear,blood`[cite: 17]
*   *Example 1st Flag:* `aura,aoe,exp`[cite: 17]
*   **Need Checkboxes:** Next to the 1st and 2nd Flag keyword boxes are "Need" checkboxes[cite: 17]. If checked, a player **must** include a matching flag keyword in their whisper to get an auto-invite[cite: 17]. If they don't, they are pushed to the overflow queue[cite: 17].

### Chat Spam Configuration
Automates your recruitment message.
*   **Spam Text:** The exact message sent to chat[cite: 17]. 
    *   **Dynamic Variable:** Include the tag `%STATS%` anywhere in your message[cite: 17]. APM will replace `%STATS%` with your real-time group needs (e.g., *"LFM Raid! Tanks: 1/2 - Heal: 1/2 - DPS: 8/11"*)[cite: 17].
*   **Channel:** Type the name of the channel (e.g., `world`) or the channel number (e.g., `4`)[cite: 17].
*   **Interval (Secs, 0=Off):** How often the message is sent[cite: 17]. Set this to `0` to completely disable chat spamming[cite: 17].

### Whisper / Invite Options
*   **Manual Invite Whisper Phrase:** The exact text APM will whisper to a queued player when you manually click the "Invite" button inside the Overflow Queue[cite: 17].
*   **Auto-Response:** The whisper APM sends to a player when they are blocked from an auto-invite and placed into the overflow queue[cite: 17].
*   **Queue Expire (Mins):** Automatically deletes players from the overflow queue if they have been waiting longer than this duration[cite: 17].

---

## 🛠️ Usage Tips & Tricks

*   **Starting & Stopping:** The addon remains completely dormant until you click the **"Start APM"** button (or Right-Click the minimap icon)[cite: 17]. Once started, the tracker will appear, and whisper parsing will begin[cite: 17]. Clicking **"Stop APM"** pauses everything, hides the tracker, and clears out any pending manual assignments[cite: 17].
*   **Auto-Pause:** If your group fills up (all role limits are met), APM will intelligently pause the chat spam[cite: 17]. It continues to catch incoming whispers into the overflow queue[cite: 17]. If someone leaves, a popup will ask if you want to resume spamming[cite: 17].
*   **Reset My Role:** Click the **"Reset My Role"** button in the bottom left of the configuration window if you need to change your own role[cite: 17]. The assignment popup will appear, allowing you to correctly catalog yourself[cite: 17].
*   **Black UI Background:** If you dislike the default transparent Blizzard dialog boxes, check the "Black UI Background" box at the bottom right[cite: 17]. This instantly reskins every APM window to a solid black background[cite: 17].
