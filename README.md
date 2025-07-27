# Hash Name Discovery Tool for RedM
A generic brute-force script for RedM that helps you reverse-engineer hash values by testing thousands of potential name combinations. Whether you're trying to uncover door names, slot IDs, component names, or weapon identifiers and some other hashes — this tool is for you.
<img width="1920" height="1080" alt="srb brute forcer" src="https://github.com/user-attachments/assets/634a11b1-7798-44a5-bc51-775bc10ed79b" />

## 📌 Disclaimer
This tool is for educational and development purposes. Brute-force testing too many strings without control can impact game performance — use batching and wait times responsibly.

## 💡 What It Does
* 🔁 Generates permutations of strings using custom prefixes, dictionary words, and suffixes.
* 🔐 Computes the hash (joaat) for each combination and compares it against a list of existing hashes (retrieved in-game).
* Skips already-known names using a JSON file.
* Logs and returns all valid newly discovered names.

## 🧠 Why Use This?
This tool is ideal when:
* You have a numeric hash but not the original string.
* You're trying to uncover hidden content, internal references, or undocumented asset names.
* You're automating the process of guessing asset strings without trial-and-error by hand.

## 🧩 Parameters
| Parameter            | Type     | Description                                                                |
| -------------------- | -------- | -------------------------------------------------------------------------- |
| `dictionary`         | `table`  | List of base words to use for combination.                                 |
| `prefixes`           | `table`  | List of string prefixes (e.g. `"DOOR_VAL_"`, `"SLOTID_"`, etc.).           |
| `suffixes`           | `table`  | List of string suffixes (e.g. `"_01"`, `"_L"`).                            |
| `maxWords`           | `number` | Max number of dictionary words to combine.                                 |
| `existingHashes`     | `table`  | List of known hashes (numeric) collected in-game.                          |
| `knownNamesJsonPath` | `string` | Path to a JSON file containing already discovered names to avoid reprints. |

## ⚙️ Example Usage
```lua
local existingHashes = {
    2978933597,
    4264525338,
    183181940,
}
local dictionary = {
    "gunsmith",
    "train",
    "prison",
    "stable",

    "int",
    "ext",
    
    "front",
    "back",
    "middle",
    "exit",
}
local prefixes = {
    "DOOR_ABE_",
    "DOOR_VAL_",
    "DOOR_ANN_",
    "DOOR_STR_",
    }
local suffixes = {
    "",
    "_01",
    "_02",
    "_1",
    "_2",
    "_L",
    "_R",
    }
local maxWords = 3
local knownNamesJsonPath = "data/doors.json"

local newFound, notFounds = BruteForce(dictionary, prefixes, suffixes, maxWords, existingHashes, knownNamesJsonPath)
```
