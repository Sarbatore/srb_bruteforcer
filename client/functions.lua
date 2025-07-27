function BruteForce(dictionary, prefixes, suffixes, maxWords, existingHashes, knownNamesJsonPath)
    prefixes = ((type(prefixes) ~= "table" or #prefixes == 0) and {""}) or prefixes
    suffixes = ((type(suffixes) ~= "table" or #suffixes == 0) and {""}) or suffixes
    maxWords = maxWords or 3
    existingHashes = existingHashes or {}

    local waitIteration = 100
    local waitDuration = 0

    -- Map pour lookup rapide des hash existants
    local existingHashMap = {}
    local unmatchedHashMap = {}
    for _, hash in ipairs(existingHashes) do
        existingHashMap[hash] = true
        unmatchedHashMap[hash] = true
    end

    -- Charger les noms connus
    local knownNamesMap = {}
    local decoded = LoadJSONFile(knownNamesJsonPath)
    if decoded and type(decoded) == "table" then
        for _, name in ipairs(decoded) do
            knownNamesMap[name] = true
        end
    end

    local newValidNames = {}
    local counter = 0

    local function permute(current, remaining, depth)
        if depth > maxWords then return end

        if #current > 0 then
            local baseName = table.concat(current, "_")

            for _, rawPrefix in ipairs(prefixes) do
                for _, rawSuffix in ipairs(suffixes) do
                    local candidate = (rawPrefix .. baseName .. rawSuffix):upper()
                    local hash = joaat(candidate)

                    if existingHashMap[hash] then
                        -- Si trouvé, on enlève ce hash des non matchés
                        unmatchedHashMap[hash] = nil

                        if knownNamesMap[candidate] then
                            print("[ALREADY DISCOVERED]", candidate)
                        else
                            table.insert(newValidNames, candidate)
                            print("[DISCOVERED]", candidate, hash)
                        end
                    end

                    counter = counter + 1
                    if counter % waitIteration == 0 then
                        Wait(waitDuration)
                    end
                end
            end
        end

        for i = 1, #remaining do
            local nextCurrent = { table.unpack(current) }
            table.insert(nextCurrent, remaining[i])

            local nextRemaining = { table.unpack(remaining) }
            table.remove(nextRemaining, i)

            permute(nextCurrent, nextRemaining, depth + 1)
        end
    end

    permute({}, dictionary, 0)
    table.sort(newValidNames)

    -- Extraire les hashes non trouvés
    local unmatchedHashes = {}
    for hash, _ in pairs(unmatchedHashMap) do
        table.insert(unmatchedHashes, hash)
    end

    return newValidNames, unmatchedHashes
end

exports("BruteForce", BruteForce)

function LoadJSONFile(jsonPath)
    if (type(jsonPath) ~= "string") then
        return {}
    end
    
    local jsonData = LoadResourceFile(GetCurrentResourceName(), jsonPath)
    if not jsonData then
        print("[ERREUR] Fichier JSON introuvable : " .. jsonPath)
        return {}
    end

    local status, decoded = pcall(function()
        return json.decode(jsonData)
    end)

    if not status then
        print("[ERREUR] Fichier JSON invalide : " .. jsonPath)
        return {}
    end

    return decoded
end