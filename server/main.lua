string = string or {}

function string:endswith(suffix)
    return self:sub(-#suffix) == suffix
end

function string:startswith(prefix)
    return self:sub(1, #prefix) == prefix
end

-- Nouveau gestionnaire pour la méthode save de BruteForce
RegisterNetEvent("BruteForce:SaveResults", function(requestData)
    local source = source
    
    -- Validation des données
    if not requestData or type(requestData) ~= "table" then
        TriggerClientEvent("BruteForce:SaveResults:Response", source, false, "Données invalides")
        return
    end
    
    local newData = requestData.data or {}
    local path = requestData.path or ""

    if (type(path) ~= "string" or path:startswith("/") or not path:endswith(".json")) then
        TriggerClientEvent("BruteForce:SaveResults:Response", source, false, "Chemin de fichier invalide")
        return
    end
    
    
    -- Construire le chemin complet
    local fullPath = "data/" .. path
    
    -- Charger le fichier existant s'il existe
    local existingData = {}
    local existingFile = LoadResourceFile(GetCurrentResourceName(), fullPath)
    if existingFile then
        local success, decoded = pcall(function()
            return json.decode(existingFile)
        end)
        if success and type(decoded) == "table" then
            existingData = decoded
            print("[BRUTEFORCE] Fichier existant chargé avec " .. #existingData .. " entrées")
        end
    end
    
    -- Créer une map hash -> nom pour les nouvelles données
    local hashToNameMap = {}
    for _, item in ipairs(newData) do
        if type(item) == "string" then
            -- C'est un nom trouvé, calculer son hash
            local hash = GetHashKey(item)
            hashToNameMap[hash] = item
        end
    end
    
    -- Créer une map pour suivre les éléments déjà traités
    local processedItems = {}
    local updatedCount = 0
    local addedCount = 0
    
    -- Mettre à jour les entrées existantes
    for i, item in ipairs(existingData) do
        if type(item) == "number" then
            -- C'est un hash, vérifier s'il a été trouvé
            if hashToNameMap[item] then
                existingData[i] = hashToNameMap[item]
                processedItems[hashToNameMap[item]] = true
                processedItems[item] = true
                updatedCount = updatedCount + 1
                print("[BRUTEFORCE] Hash " .. item .. " remplacé par " .. hashToNameMap[item])
            else
                processedItems[item] = true
            end
        elseif type(item) == "string" then
            -- C'est déjà un nom, le marquer comme traité
            processedItems[item] = true
            local hash = GetHashKey(item)
            processedItems[hash] = true
        end
    end
    
    -- Ajouter les nouvelles entrées qui n'existent pas encore
    for _, item in ipairs(newData) do
        if not processedItems[item] then
            table.insert(existingData, item)
            processedItems[item] = true
            addedCount = addedCount + 1
        end
    end
    
    table.sort(existingData, function (a, b)
        return tostring(a):lower() < tostring(b):lower()
    end)
    
    -- Sauvegarder le fichier mis à jour
    local jsonData = json.encode(existingData, { indent = true })
    local success = SaveResourceFile(GetCurrentResourceName(), fullPath, jsonData, -1)
    
    if success then
        print("[BRUTEFORCE] Fichier sauvegardé: " .. fullPath)
        print("[BRUTEFORCE] Total d'entrées: " .. #existingData)
        print("[BRUTEFORCE] Hashes remplacés: " .. updatedCount)
        print("[BRUTEFORCE] Nouvelles entrées: " .. addedCount)
        TriggerClientEvent("BruteForce:SaveResults:Response", source, true, 
            string.format("Fichier sauvegardé: %s (%d mis à jour, %d ajoutés)", fullPath, updatedCount, addedCount))
    else
        print("[BRUTEFORCE] Erreur lors de la sauvegarde: " .. fullPath)
        TriggerClientEvent("BruteForce:SaveResults:Response", source, false, "Erreur lors de la sauvegarde du fichier")
    end
end)