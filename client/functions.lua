function BruteForce(dictionary, prefixes, suffixes, maxWords, existingHashes, knownNamesJsonPath)
    prefixes = ((type(prefixes) ~= "table" or #prefixes == 0) and {""}) or prefixes
    suffixes = ((type(suffixes) ~= "table" or #suffixes == 0) and {""}) or suffixes
    maxWords = maxWords or 3
    existingHashes = existingHashes or {}  -- TABLE DE HASH (numeriques) récupérés en jeu

    local waitIteration = 100
    local waitDuration = 0

    -- Convertir existingHashes en map pour lookup rapide
    local existingHashMap = {}
    for i, hash in ipairs(existingHashes) do
        existingHashMap[hash] = i
    end

    -- Charger les noms connus depuis un fichier JSON
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

                    -- Si le hash existe en jeu
                    if existingHashMap[hash] then
                        table.remove(existingHashes, existingHashMap[hash])
                        -- Et si le nom n'est pas encore connu
                        if knownNamesMap[candidate] then
                            print("[ALREADY DISCOVERED]", candidate)
                        else
                            table.insert(newValidNames, candidate)
                            print("[DISCOVERED]", candidate, hash)
                        end
                    else
                        --print("[INVALID]", candidate)
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
    return newValidNames, existingHashes
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