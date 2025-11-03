RegisterCommand("bruteforce", function()
    local hashes = {}
    local wordLists = {}

    hashes = {
       `WEAPON_REVOLVER_CATTLEMAN`
    }

    wordLists[#wordLists+1] = {
        "WEAPON_REVOLVER"
    }

    wordLists[#wordLists+1] = {
        "CATTLEMAN"
    }

    local bf = BruteForce:new({
        wordLists = wordLists,
        separator = "_",
        upperCase = true,
        existingHashes = hashes
    })

    bf:execute()
    bf:save("weapons/weapons.json", function(success, message)
        if success then
            print("Sauvegarde réussie:", message)
        else
            print("Erreur de sauvegarde:", message)
        end
    end)
end)