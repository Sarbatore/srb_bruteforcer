BruteForce = {}
BruteForce.__index = BruteForce

-- Constructeur
function BruteForce:new(config)
    local instance = setmetatable({}, BruteForce)
    
    -- Configuration modulaire : wordLists[position] = {liste de mots pour cette position}
    -- Exemple: wordLists = { {"WEAPON"}, {"PISTOL", "RIFLE"}, {"MK2", "GOLD"} }
    -- Générera: WEAPON_PISTOL_MK2, WEAPON_PISTOL_GOLD, WEAPON_RIFLE_MK2, etc.
    instance.wordLists = config.wordLists or {{""}}
    instance.separator = config.separator or "_"
    instance.upperCase = config.upperCase ~= false -- true par défaut
    instance.existingHashes = config.existingHashes or {}
    instance.knownNamesJsonPath = config.knownNamesJsonPath or nil
    
    -- Paramètres de performance
    instance.waitIteration = config.waitIteration or 100
    instance.waitDuration = config.waitDuration or 0
    
    -- État interne
    instance.existingHashMap = {}
    instance.unmatchedHashMap = {}
    instance.knownNamesMap = {}
    instance.newValidNames = {}
    instance.counter = 0
    instance.isRunning = false
    instance.isPaused = false
    
    -- Initialisation
    instance:_initializeHashMaps()
    instance:_loadKnownNames()
    
    return instance
end

-- Initialiser les maps de hash
function BruteForce:_initializeHashMaps()
    for _, hash in ipairs(self.existingHashes) do
        self.existingHashMap[hash] = true
        self.unmatchedHashMap[hash] = true
    end
end

-- Charger les noms connus depuis JSON
function BruteForce:_loadKnownNames()
    if not self.knownNamesJsonPath then return end
    
    local decoded = LoadJSONFile(self.knownNamesJsonPath)
    if decoded and type(decoded) == "table" then
        for _, name in ipairs(decoded) do
            self.knownNamesMap[name] = true
        end
    end
end

-- Génération récursive des combinaisons avec positions modulaires
function BruteForce:_generateCombinations(currentCombination, positionIndex)
    if not self.isRunning then return end
    
    -- Gestion de la pause
    while self.isPaused and self.isRunning do
        Wait(100)
    end
    
    -- Si on a traité toutes les positions, on teste la combinaison
    if positionIndex > #self.wordLists then
        if #currentCombination > 0 then
            -- Joindre les mots avec le séparateur
            local candidate = table.concat(currentCombination, self.separator)
            
            -- Appliquer la transformation en majuscules si nécessaire
            if self.upperCase then
                candidate = candidate:upper()
            end
            
            -- Tester le hash
            local hash = joaat(candidate)
            
            if self.existingHashMap[hash] then
                -- Si trouvé, on enlève ce hash des non matchés
                self.unmatchedHashMap[hash] = nil
                
                if self.knownNamesMap[candidate] then
                    print("[ALREADY DISCOVERED]", candidate)
                else
                    table.insert(self.newValidNames, candidate)
                    print("[DISCOVERED]", candidate, hash)
                end
            end
            
            self.counter = self.counter + 1
            if self.counter % self.waitIteration == 0 then
                Wait(self.waitDuration)
            end
        end
        return
    end
    
    -- Pour la position actuelle, tester tous les mots possibles
    local wordsAtPosition = self.wordLists[positionIndex]
    if type(wordsAtPosition) == "table" then
        for _, word in ipairs(wordsAtPosition) do
            -- Ajouter le mot à la combinaison actuelle
            local nextCombination = { table.unpack(currentCombination) }
            
            -- Ajouter le mot seulement s'il n'est pas vide
            if word ~= "" then
                table.insert(nextCombination, word)
            end
            
            -- Continuer avec la position suivante
            self:_generateCombinations(nextCombination, positionIndex + 1)
        end
    end
end

-- Exécuter le brute force
function BruteForce:execute()
    if self.isRunning then
        print("[BRUTEFORCE] Déjà en cours d'exécution")
        return false
    end
    
    self.isRunning = true
    self.isPaused = false
    self.newValidNames = {}
    self.counter = 0
    
    print("[BRUTEFORCE] Démarrage...")
    print("[BRUTEFORCE] Nombre de positions:", #self.wordLists)
    for i, wordList in ipairs(self.wordLists) do
        print(string.format("[BRUTEFORCE] Position %d: %d mots", i, #wordList))
    end
    print("[BRUTEFORCE] Séparateur:", self.separator)
    print("[BRUTEFORCE] Majuscules:", self.upperCase and "OUI" or "NON")
    print("[BRUTEFORCE] Hashes à trouver:", #self.existingHashes)
    
    self:_generateCombinations({}, 1)
    
    self.isRunning = false
    table.sort(self.newValidNames)
    
    print("[BRUTEFORCE] Terminé!")
    print("[BRUTEFORCE] Combinaisons testées:", self.counter)
    print("[BRUTEFORCE] Nouveaux noms trouvés:", #self.newValidNames)
    
    return true
end

-- Obtenir les résultats
function BruteForce:getResults()
    local unmatchedHashes = {}
    for hash, _ in pairs(self.unmatchedHashMap) do
        table.insert(unmatchedHashes, hash)
    end
    
    -- Créer une liste combinée : noms trouvés + hashes non trouvés
    local combinedList = {}
    
    -- Ajouter tous les noms trouvés
    for _, name in ipairs(self.newValidNames) do
        table.insert(combinedList, name)
    end
    
    -- Ajouter tous les hashes non trouvés
    for _, hash in ipairs(unmatchedHashes) do
        table.insert(combinedList, hash)
    end
    
    return {
        newValidNames = self.newValidNames,
        unmatchedHashes = unmatchedHashes,
        combinedList = combinedList,
        totalTested = self.counter,
        totalFound = #self.newValidNames,
        totalUnmatched = #unmatchedHashes
    }
end

-- Mettre en pause
function BruteForce:pause()
    if self.isRunning and not self.isPaused then
        self.isPaused = true
        print("[BRUTEFORCE] Mis en pause")
        return true
    end
    return false
end

-- Reprendre
function BruteForce:resume()
    if self.isRunning and self.isPaused then
        self.isPaused = false
        print("[BRUTEFORCE] Reprise")
        return true
    end
    return false
end

-- Arrêter
function BruteForce:stop()
    if self.isRunning then
        self.isRunning = false
        self.isPaused = false
        print("[BRUTEFORCE] Arrêté")
        return true
    end
    return false
end

-- Obtenir l'état
function BruteForce:getStatus()
    return {
        isRunning = self.isRunning,
        isPaused = self.isPaused,
        counter = self.counter,
        found = #self.newValidNames
    }
end

-- Ajouter des hashes à rechercher
function BruteForce:addHashes(hashes)
    for _, hash in ipairs(hashes) do
        if not self.existingHashMap[hash] then
            table.insert(self.existingHashes, hash)
            self.existingHashMap[hash] = true
            self.unmatchedHashMap[hash] = true
        end
    end
end

-- Mettre à jour les listes de mots par position
function BruteForce:setWordLists(wordLists)
    if type(wordLists) == "table" and #wordLists > 0 then
        self.wordLists = wordLists
    else
        print("[BRUTEFORCE] Erreur: wordLists doit être une table non vide")
    end
end

-- Mettre à jour le séparateur
function BruteForce:setSeparator(separator)
    self.separator = separator or "_"
end

-- Activer/désactiver les majuscules
function BruteForce:setUpperCase(upperCase)
    self.upperCase = upperCase ~= false
end

-- Reset complet
function BruteForce:reset()
    self.isRunning = false
    self.isPaused = false
    self.newValidNames = {}
    self.counter = 0
    self:_initializeHashMaps()
end

-- Sauvegarder les résultats sur le serveur
function BruteForce:save(path, callback)
    if type(path) ~= "string" then
        print("[BRUTEFORCE] Erreur: chemin du dossier invalide")
        if callback then callback(false, "Chemin du dossier invalide") end
        return false
    end
    
    local results = self:getResults()
    
    print("[BRUTEFORCE] Sauvegarde des résultats...")
    print("[BRUTEFORCE] Total d'éléments:", #results.combinedList)
    print("[BRUTEFORCE] - Noms trouvés:", #results.newValidNames)
    print("[BRUTEFORCE] - Hashes non trouvés:", #results.unmatchedHashes)
    
    TriggerServerEvent("BruteForce:SaveResults", {
        path = path,
        data = results.combinedList
    })
    
    if callback then
        -- Attendre la réponse du serveur
        RegisterNetEvent("BruteForce:SaveResults:Response")
        local handler
        handler = AddEventHandler("BruteForce:SaveResults:Response", function(success, message)
            callback(success, message)
            RemoveEventHandler(handler)
        end)
    end
    
    return true
end

exports("BruteForceClass", function() return BruteForce end)

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