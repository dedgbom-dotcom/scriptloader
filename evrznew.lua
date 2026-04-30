-- ========================================================================== --
--                               1. JUNKIE API SETUP                          --
-- ========================================================================== --
local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service = "rzpv"
Junkie.identifier = "1040009"
Junkie.provider = "rzpv"

local keyFileName = "rzprivate_verified_key.txt"

local function hasFileSystemSupport()
	return pcall(function()
		return type(writefile) == "function" and type(readfile) == "function"
	end)
end

local function saveVerifiedKey(key)
	if not hasFileSystemSupport() then
		return
	end
	pcall(function()
		writefile(keyFileName, key)
	end)
end

local function loadVerifiedKey()
	if not hasFileSystemSupport() then
		return nil
	end
	local ok, content = pcall(function()
		return readfile(keyFileName)
	end)
	if not ok or not content or content == "" then
		return nil
	end
	return content
end

local function clearSavedKey()
	if not hasFileSystemSupport() then
		return
	end
	pcall(function()
		delfile(keyFileName)
	end)
end

-- ========================================================================== --
--                        2. YOUR MAIN SCRIPT GOES HERE                       --
-- ========================================================================== --
local function LoadMainHub()
	-- ========================================================================== --
	--                      RZPRIVATE - EVADE (OBSIDIAN VERSION)                  --
	--                            by iruz | version 3.1                           --
	-- ========================================================================== --

	task.spawn(function()
		local success, err = pcall(function()
			local ReplicatedStorage = game:GetService("ReplicatedStorage")

			-- Mengambil ModuleScript yang bermasalah dari internal game Evade
			local jointsModulePath = ReplicatedStorage:WaitForChild("Modules")
				:WaitForChild("Character")
				:WaitForChild("CharacterTable")
				:WaitForChild("CharacterController")
				:WaitForChild("Global")
				:WaitForChild("Rig")
				:WaitForChild("Joints")

			local jointsModule = require(jointsModulePath)

			-- Menyimpan fungsi asli bawaan game
			local oldInterpolateLimbs = jointsModule.InterpolateLimbs

			-- Menimpa fungsi tersebut dengan versi yang aman (Protected)
			jointsModule.InterpolateLimbs = function(...)
				-- Menjalankan fungsi asli menggunakan pcall
				local runSuccess, result = pcall(oldInterpolateLimbs, ...)

				-- Jika fungsi asli gagal (karena argument nil, dll), kita diamkan saja
				if not runSuccess then
					return nil
				end

				-- Jika berhasil, kembalikan hasilnya seperti biasa
				return result
			end
		end)
	end)

	-- ========================================================================== --
	--                      EVADE EMOTE ERROR HANDLER (PATCH)                     --
	-- ========================================================================== --

	task.spawn(function()
		local success, err = pcall(function()
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local emotesFolder = ReplicatedStorage:WaitForChild("Items"):WaitForChild("Emotes")

			-- Melakukan looping ke semua data Emote di dalam game
			for _, emoteFolder in ipairs(emotesFolder:GetChildren()) do
				local moduleClassic = emoteFolder:FindFirstChild("EmoteModuleClassic")

				if moduleClassic and moduleClassic:IsA("ModuleScript") then
					-- Menjalankan require secara asynchronous agar tidak bikin lag saat loading
					task.spawn(function()
						local req = require(moduleClassic)
						if type(req) == "table" then
							-- Membungkus setiap fungsi di dalam emote dengan pcall
							for funcName, func in pairs(req) do
								if type(func) == "function" then
									local oldFunc = func
									req[funcName] = function(...)
										local runSuccess, result = pcall(oldFunc, ...)
										if not runSuccess then
											return nil
										end
										return result
									end
								end
							end
						end
					end)
				end
			end
		end)
	end)

	-- ========================================================================== --
	--                 EVADE INFINITE YIELD ERROR HANDLER (PATCH 3)               --
	-- ========================================================================== --
	task.spawn(function()
		local success, err = pcall(function()
			local oldNamecall
			oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
				local method = getnamecallmethod()
				local args = { ... }

				-- Jika game menggunakan fungsi WaitForChild
				if method == "WaitForChild" and type(args[1]) == "string" then
					-- Jika game sedang mencari "BoundingBox" tanpa batas waktu
					if args[1] == "BoundingBox" and args[2] == nil then
						-- Kita suntikkan batas waktu 9999 detik secara diam-diam
						-- agar tulisan kuning 'Infinite yield' tidak muncul
						return oldNamecall(self, args[1], 9999)
					end
				end

				return oldNamecall(self, ...)
			end)
		end)
	end)

	-- ========================================================================== --
	--                 EVADE TOOL & VISUAL ERROR HANDLER (PATCH 4)                --
	-- ========================================================================== --
	task.spawn(function()
		local success, err = pcall(function()
			local ReplicatedStorage = game:GetService("ReplicatedStorage")

			-- 1. Membungkus modul VisualTools internal Evade
			local visualToolsPath = ReplicatedStorage:WaitForChild("Modules")
				:WaitForChild("Character")
				:WaitForChild("CharacterTable")
				:WaitForChild("CharacterController")
				:WaitForChild("Global")
				:WaitForChild("Rig")
				:WaitForChild("VisualTools")

			local vtModule = require(visualToolsPath)
			if type(vtModule) == "table" then
				for k, v in pairs(vtModule) do
					if type(v) == "function" then
						local oldFunc = v
						vtModule[k] = function(...)
							local s, r = pcall(oldFunc, ...)
							if not s then
								return nil
							end
							return r
						end
					end
				end
			end

			-- 2. Membungkus semua skrip karakter dari alat (seperti StunBaton)
			local toolsFolder = ReplicatedStorage:WaitForChild("Tools")
			for _, tool in ipairs(toolsFolder:GetChildren()) do
				local variants = tool:FindFirstChild("Variants")
				if variants then
					for _, variant in ipairs(variants:GetChildren()) do
						local charModule = variant:FindFirstChild("Character")
						if charModule and charModule:IsA("ModuleScript") then
							task.spawn(function()
								local req = require(charModule)
								if type(req) == "table" then
									for k, v in pairs(req) do
										if type(v) == "function" then
											local oldFunc = v
											req[k] = function(...)
												local s, r = pcall(oldFunc, ...)
												if not s then
													return nil
												end
												return r
											end
										end
									end
								end
							end)
						end
					end
				end
			end
		end)
	end)

	-- ========================================================================== --
	--                            SERVICES & MODULES                               --
	-- ========================================================================== --

	local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
	local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
	local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
	local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

	local Options = Library.Options
	local Toggles = Library.Toggles

	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local UserInputService = game:GetService("UserInputService")
	local TeleportService = game:GetService("TeleportService")
	local HttpService = game:GetService("HttpService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local MarketplaceService = game:GetService("MarketplaceService")
	local VirtualUser = game:GetService("VirtualUser")
	local TweenService = game:GetService("TweenService")
	local GuiService = game:GetService("GuiService")
	local StarterGui = game:GetService("StarterGui")
	local Lighting = game:GetService("Lighting")
	local placeId = game.PlaceId
	local jobId = game.JobId

	-- ========================================================================== --
	--                    SAFE PLAYER HELPERS (ANTI-CRASH & ANTI-DEAD)            --
	-- ========================================================================== --

	local function safeGetHumanoid(character)
		if not character then
			return nil
		end
		return character:FindFirstChildOfClass("Humanoid")
	end

	local function safeIsPlayerDowned(targetPlayer)
		if not targetPlayer or not targetPlayer.Character then
			return false
		end

		local success, result = pcall(function()
			local char = targetPlayer.Character
			-- Pastikan Humanoid ada (mencegah error DeathHUD)
			if not char:FindFirstChildOfClass("Humanoid") then
				return false
			end

			-- Cek Attribute Downed
			local isDowned = char:GetAttribute("Downed") == true

			-- Cek Folder Ragdolls (untuk akurasi mayat)
			local ragdolls = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Ragdolls")
			local inRagdoll = ragdolls and ragdolls:FindFirstChild(targetPlayer.Name)

			-- CEK REVIVER (Kunci agar tidak spam error UserId)
			-- Jika 'Reviver' sudah ada isinya, berarti sudah ada yang menolong. JANGAN DISPAM.
			local beingRevived = char:GetAttribute("Reviver") ~= nil

			return (isDowned or inRagdoll) and not beingRevived
		end)
		return success and result or false
	end

	local function safeGetDownedPosition(targetPlayer)
		if not targetPlayer then
			return nil
		end
		local success, position = pcall(function()
			-- Cek di Ragdoll dulu (Karena ini posisi tubuh yang sebenarnya di tanah)
			local ragdolls = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Ragdolls")
			local ragdoll = ragdolls and ragdolls:FindFirstChild(targetPlayer.Name)

			if ragdoll then
				local root = ragdoll:FindFirstChild("HumanoidRootPart")
					or ragdoll:FindFirstChild("Torso")
					or ragdoll:FindFirstChild("Head")
				if root then
					return root.Position
				end
			end

			-- Kalau tidak ada ragdoll, baru cek karakter asli
			if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
				return targetPlayer.Character.HumanoidRootPart.Position
			end
			return nil
		end)
		return success and position or nil
	end

	-- ========================================================================== --
	--                          NOTIFICATION SYSTEM                               --
	-- ========================================================================== --

	local isScriptLoading = true
	local notificationsEnabled = true -- (default ON)

	local function Success(title, message, duration)
		if isScriptLoading or not notificationsEnabled then
			return
		end
		Library:Notify({
			Title = title,
			Description = message,
			Time = duration or 2,
			Icon = "rbxassetid://7733658504", -- Icon Centang
		})
	end

	local function Error(title, message, duration)
		if isScriptLoading or not notificationsEnabled then
			return
		end
		Library:Notify({
			Title = title,
			Description = message,
			Time = duration or 3,
			Icon = "rbxassetid://7733658421", -- Icon Silang (X)
		})
	end

	local function Info(title, message, duration)
		if isScriptLoading or not notificationsEnabled then
			return
		end
		Library:Notify({
			Title = title,
			Description = message,
			Time = duration or 2,
			Icon = "rbxassetid://7733658335", -- Icon Info (i)
		})
	end

	local function Warning(title, message, duration)
		if isScriptLoading or not notificationsEnabled then
			return
		end
		Library:Notify({
			Title = title,
			Description = message,
			Time = duration or 2,
			Icon = "rbxassetid://7733658117", -- Icon Segitiga Peringatan
		})
	end

	-- ========================================================================== --
	--                         AUTO SELF REVIVE MODULE                            --
	-- ========================================================================== --

	local AutoSelfReviveModule = (function()
		local enabled = false
		local method = "Spawnpoint"
		local connections = {}
		local lastSavedPosition = nil
		local hasRevived = false
		local isReviving = false

		local function cleanupConnections()
			for _, conn in pairs(connections) do
				if conn and conn.Disconnect then
					pcall(function()
						conn:Disconnect()
					end)
				end
			end
			connections = {}
		end

		local function handleDowned(character)
			local success, isDowned = pcall(function()
				return character:GetAttribute("Downed")
			end)

			if success and isDowned and not isReviving then
				isReviving = true

				if method == "Spawnpoint" then
					if not hasRevived then
						hasRevived = true
						local char = player.Character
						if char then
							local hum = char:WaitForChild("Humanoid", 5)
							if hum then
								pcall(function()
									ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
								end)
								Success("Auto Self Revive", "Reviving at spawnpoint...", 2)
							end
						end

						task.delay(10, function()
							hasRevived = false
						end)
						task.delay(1, function()
							isReviving = false
						end)
					else
						isReviving = false
					end
				elseif method == "Fake Revive" then
					local hrp = character:FindFirstChild("HumanoidRootPart")
					if hrp then
						lastSavedPosition = hrp.Position
					end

					task.spawn(function()
						pcall(function()
							ReplicatedStorage:WaitForChild("Events")
								:WaitForChild("Player")
								:WaitForChild("ChangePlayerMode")
								:FireServer(true)
						end)

						Success("Auto Self Revive", "Saving position and reviving...", 2)

						local newCharacter
						repeat
							newCharacter = player.Character
							task.wait()
						until newCharacter
							and newCharacter:FindFirstChild("HumanoidRootPart")
							and newCharacter ~= character

						if newCharacter then
							local newHRP = newCharacter:FindFirstChild("HumanoidRootPart")
							if lastSavedPosition and newHRP then
								task.wait(0.1)
								pcall(function()
									newHRP.CFrame = CFrame.new(lastSavedPosition)
								end)
								Success("Auto Self Revive", "Teleported back to saved position!", 2)
							end
						end

						isReviving = false
					end)
				end
			end
		end

		local function setupCharacter(character)
			if not character then
				return
			end
			task.wait(0.5)

			local downedConnection = character:GetAttributeChangedSignal("Downed"):Connect(function()
				handleDowned(character)
			end)

			table.insert(connections, downedConnection)
		end

		local function start()
			if enabled then
				return
			end
			enabled = true

			cleanupConnections()

			local character = player.Character
			if character then
				setupCharacter(character)
			end

			local charAddedConnection = player.CharacterAdded:Connect(function(newChar)
				setupCharacter(newChar)
			end)

			table.insert(connections, charAddedConnection)

			Success("Auto Self Revive", "Enabled with method: " .. method, 2)
		end

		local function stop()
			if not enabled then
				return
			end
			enabled = false

			cleanupConnections()
			hasRevived = false
			isReviving = false
			lastSavedPosition = nil

			Info("Auto Self Revive", "Disabled", 2)
		end

		return {
			Start = start,
			Stop = stop,
			SetMethod = function(newMethod)
				method = newMethod
				if enabled then
					Info("Auto Self Revive", "Method changed to: " .. newMethod, 2)
				end
			end,
			IsEnabled = function()
				return enabled
			end,
		}
	end)()

	-- ========================================================================== --
	--                         INSTANT REVIVE MODULE                              --
	-- ========================================================================== --

	local InstantReviveModule = (function()
		local enabled = false
		local reviveWhileEmoting = false
		local reviveDelay = 0.15
		local reviveRange = 10

		local handle = nil
		local stateConnection = nil
		local isCurrentlyEmoting = false

		local interactEvent =
			ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact")

		-- Check if player is emoting
		local function updateEmoteStatus()
			if not player.Character then
				isCurrentlyEmoting = false
				return
			end
			local state = player.Character:GetAttribute("State")
			isCurrentlyEmoting = state and string.find(state, "Emoting")
		end

		-- ✅ FUNGSI YANG DIPERBAIKI (GANTI YANG LAMA)
		local function isPlayerDowned(pl)
			-- Gunakan helper function yang sudah dibuat
			return safeIsPlayerDowned(pl)
		end

		-- Main revive loop
local function reviveLoop()
    while enabled do
        -- Skip if emoting and reviveWhileEmoting is disabled
        if isCurrentlyEmoting and not reviveWhileEmoting then
            task.wait(0.3)
        else
            local myChar = player.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local myHRP = myChar.HumanoidRootPart

                -- Loop through all players
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= player and pl.Character then
                        -- ✅ GUNAKAN SAFE CHECK
                        if isPlayerDowned(pl) then
                            -- ✅ GUNAKAN SAFE GET POSITION
                            local targetPos = safeGetDownedPosition(pl)

                            if targetPos then
                                local dist = (myHRP.Position - targetPos).Magnitude

                                -- Revive if in range
                                if dist <= reviveRange then
                                    pcall(function()
                                        interactEvent:FireServer("Revive", true, pl.Name)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end

        task.wait(reviveDelay)
    end
end

		-- Start instant revive
		local function start()
			if handle then
				return
			end
			enabled = true

			updateEmoteStatus()

			-- Setup emote detection
			if player.Character then
				stateConnection = player.Character:GetAttributeChangedSignal("State"):Connect(updateEmoteStatus)
			end

			-- Handle character respawn
			player.CharacterAdded:Connect(function(char)
				if stateConnection then
					stateConnection:Disconnect()
				end
				stateConnection = char:GetAttributeChangedSignal("State"):Connect(updateEmoteStatus)
				updateEmoteStatus()
			end)

			-- Start revive loop
			handle = task.spawn(reviveLoop)

			Success("Instant Revive", "Activated (Delay: " .. reviveDelay .. "s)", 2)
		end

		-- Stop instant revive
		local function stop()
			enabled = false

			if handle then
				task.cancel(handle)
				handle = nil
			end

			if stateConnection then
				stateConnection:Disconnect()
				stateConnection = nil
			end

			isCurrentlyEmoting = false

			Info("Instant Revive", "Disabled", 2)
		end

		return {
			Start = start,
			Stop = stop,
			IsEnabled = function()
				return enabled
			end,
			SetDelay = function(delay)
				reviveDelay = delay
				Success("Instant Revive", "Delay set to " .. delay .. "s", 1)
			end,
			SetReviveWhileEmoting = function(state)
				reviveWhileEmoting = state
			end,
			SetRange = function(range)
				reviveRange = range
				Success("Instant Revive", "Range set to " .. range .. " studs", 1)
			end,
		}
	end)()

	-- ========================================================================== --
	--                         AUTO WHISTLE MODULE                                --
	-- ========================================================================== --

	local AutoWhistleModule = (function()
		local enabled = false
		local whistleHandle = nil
		local whistleDelay = 1 -- detik

		local function startWhistle()
			if whistleHandle then
				return
			end

			whistleHandle = task.spawn(function()
				while enabled do
					pcall(function()
						ReplicatedStorage.Events.Character.Whistle:FireServer()
					end)
					task.wait(whistleDelay)
				end
				whistleHandle = nil
			end)
		end

		local function stopWhistle()
			enabled = false
			if whistleHandle then
				task.cancel(whistleHandle)
				whistleHandle = nil
			end
		end

		local function start()
			if enabled then
				return
			end
			enabled = true
			startWhistle()
			Success("Auto Whistle", "Activated", 2)
		end

		local function stop()
			if not enabled then
				return
			end
			enabled = false
			stopWhistle()
			Info("Auto Whistle", "Disabled", 2)
		end

		return {
			Start = start,
			Stop = stop,
			IsEnabled = function()
				return enabled
			end,
			SetDelay = function(delay)
				whistleDelay = delay
				Success("Auto Whistle", "Delay set to " .. delay .. "s", 1)
			end,
		}
	end)()

	-- ========================================================================== --
	--                  ANTI-NEXTBOT & UNIFIED FARM (INTEGRATED)                  --
	-- ========================================================================== --

	local AntiNextbotModule = (function()
		local enabled = false
		local defenseTask = nil
		local detectionRange = 40
		local evadeType = "Distance"
		local evadeDistance = 35

		local function getOrCreateSafeSpot()
			local part = workspace:FindFirstChild("RZ_SecurityPart")
			if not part then
				part = Instance.new("Part", workspace)
				part.Name = "RZ_SecurityPart"
				part.Size = Vector3.new(100, 2, 100)
				part.Position = Vector3.new(math.random(5000, 8000), 5000, math.random(5000, 8000))
				part.Anchored = true
				part.CanCollide = true
				part.Color = Color3.fromRGB(255, 0, 0)
				part.Transparency = 0.5
			end
			return part
		end

		local function isNextbot(model)
			if not model:IsA("Model") or model == player.Character then
				return false
			end
			-- Evade sering menaruh bot di folder NPCs atau Game.NPCs
			-- Bot biasanya punya HumanoidRootPart tapi TIDAK punya atribut "Downed"
			local hasHrp = model:FindFirstChild("HumanoidRootPart")
			local isNotPlayer = not Players:GetPlayerFromCharacter(model)
			local isNotRagdoll = not model:GetAttribute("Downed")

			return hasHrp and isNotPlayer and isNotRagdoll
		end

		local function scanAndEvade()
			local farmsSuppressed = false
			local prevMoney, prevTicket, prevAFK = false, false, false

			while enabled do
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")

				if hrp and not char:GetAttribute("Downed") then
					local nearestDist = math.huge
					local nearestBot = nil

					-- SCAN SEMUA FOLDER KEMUNGKINAN BOT (Lebih Luas)
					local scanFolders = {
						workspace:FindFirstChild("NPCs"),
						workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("NPCs"),
						workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players"), -- Bot di mode Pro/Social
					}

					for _, folder in pairs(scanFolders) do
						if folder then
							for _, model in ipairs(folder:GetChildren()) do
								if isNextbot(model) then
									local bHrp = model.HumanoidRootPart
									local dist = (hrp.Position - bHrp.Position).Magnitude
									if dist < nearestDist then
										nearestDist = dist
										nearestBot = model
									end
								end
							end
						end
					end

					local isTooClose = (nearestDist <= detectionRange)

					-- JIKA BOT DEKAT: Matikan Farm dan Kabur!
					if isTooClose and nearestBot then
						-- Matikan farm agar tidak TP balik ke arah bot
						if not farmsSuppressed then
							if Toggles.AutoFarmMoney and Toggles.AutoFarmMoney.Value then
								prevMoney = true
								Toggles.AutoFarmMoney:SetValue(false)
							end
							if Toggles.AutoFarmTickets and Toggles.AutoFarmTickets.Value then
								prevTicket = true
								Toggles.AutoFarmTickets:SetValue(false)
							end
							farmsSuppressed = true
							Warning("Anti-Bot", "Nextbot Terdeteksi! Menghindar...", 1)
						end

						-- EKSEKUSI KABUR (Mode instan)
						if evadeType == "Spawn" then
							local spawns = workspace:FindFirstChild("Game")
								and workspace.Game:FindFirstChild("Map")
								and workspace.Game.Map:FindFirstChild("Parts")
								and workspace.Game.Map.Parts:FindFirstChild("Spawns")
							if spawns and #spawns:GetChildren() > 0 then
								local s = spawns:GetChildren()
								hrp.CFrame = s[math.random(1, #s)].CFrame + Vector3.new(0, 3, 0)
							else
								hrp.CFrame = getOrCreateSafeSpot().CFrame + Vector3.new(0, 5, 0)
							end
						elseif evadeType == "Players" then
							local plrs = {}
							for _, p in pairs(Players:GetPlayers()) do
								if
									p ~= player
									and p.Character
									and p.Character:FindFirstChild("HumanoidRootPart")
									and not p.Character:GetAttribute("Downed")
								then
									table.insert(plrs, p)
								end
							end
							if #plrs > 0 then
								hrp.CFrame = plrs[math.random(1, #plrs)].Character.HumanoidRootPart.CFrame
									+ Vector3.new(0, 3, 0)
							end
						else -- Mode Distance (Paling aman: Langsung ke langit jika sangat dekat)
							local direction = (hrp.Position - nearestBot.HumanoidRootPart.Position).Unit
							hrp.CFrame = hrp.CFrame + (direction * evadeDistance) + Vector3.new(0, 5, 0)
						end
						task.wait(0.3) -- Cooldown biar gak kedip-kedip (seizure)
					elseif not isTooClose and farmsSuppressed then
						-- Bot sudah jauh, nyalakan farm lagi
						if prevMoney then
							Toggles.AutoFarmMoney:SetValue(true)
							prevMoney = false
						end
						if prevTicket then
							Toggles.AutoFarmTickets:SetValue(true)
							prevTicket = false
						end
						farmsSuppressed = false
						Success("Anti-Bot", "Bot sudah jauh. Melanjutkan Farm.", 1)
					end
				end
				task.wait(0.05) -- Kecepatan scan dipercepat (20x per detik)
			end
		end

		return {
			Start = function()
				enabled = true
				defenseTask = task.spawn(scanAndEvade)
				Success("Defense", "Anti-Nextbot Aktif!", 2)
			end,
			Stop = function()
				enabled = false
				if defenseTask then
					task.cancel(defenseTask)
				end
				Info("Defense", "Anti-Nextbot Mati", 2)
			end,
			SetRange = function(v)
				detectionRange = v
			end,
			SetType = function(v)
				evadeType = v
			end,
			SetEvadeDistance = function(v)
				evadeDistance = v
			end,
		}
	end)()

	local UnifiedAutoFarm = (function()
    local currentMode = "None"
    local farmTask = nil
    local safeSpotPos = Vector3.new(5000, 5000, 5000)

    local interactEvent =
        ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact")
    local changeModeEvent =
        ReplicatedStorage:WaitForChild("Events"):WaitForChild("Player"):WaitForChild("ChangePlayerMode")

    local function getOrCreateSafeSpot()
        local existing = workspace:FindFirstChild("RZ_SecurityPart")
        if existing then
            return existing
        end
        local part = Instance.new("Part", workspace)
        part.Name = "RZ_SecurityPart"
        part.Size = Vector3.new(50, 2, 50)
        part.Position = safeSpotPos
        part.Anchored = true
        part.CanCollide = true
        part.Transparency = 0.5
        part.Color = Color3.fromRGB(0, 255, 100)
        return part
    end

    local function startMasterLoop()
        if farmTask then
            task.cancel(farmTask)
        end
        farmTask = task.spawn(function()
            local currentTicket = nil
            local ticketProcessedTime = 0

            while currentMode ~= "None" do
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local safePart = getOrCreateSafeSpot()
                local waitTime = 0.1

                if hrp then
                    -- 1. AUTO RESPAWN PROTECTION
                    if char:GetAttribute("Downed") then
                        pcall(function()
                            changeModeEvent:FireServer(true)
                        end)
                        task.wait(0.5)
                        hrp.CFrame = safePart.CFrame + Vector3.new(0, 5, 0)
                        task.wait(1)
                    else
                        -- 2. MONEY FARM (Revive Downed Players)
                        if currentMode == "Money" then
                            local target = nil
                            local minDist = math.huge

                            for _, pl in ipairs(Players:GetPlayers()) do
                                if pl ~= player and safeIsPlayerDowned(pl) then
                                    local pos = safeGetDownedPosition(pl)
                                    if pos then
                                        local d = (hrp.Position - pos).Magnitude
                                        if d < minDist then
                                            target = pl
                                            minDist = d
                                        end
                                    end
                                end
                            end

                            if target then
                                local tPos = safeGetDownedPosition(target)
                                hrp.CFrame = CFrame.new(tPos.X, tPos.Y - 3.5, tPos.Z)
                                task.wait(0.1)

                                if safeIsPlayerDowned(target) then
                                    pcall(function()
                                        interactEvent:FireServer("Revive", true, target.Name)
                                    end)
                                    task.wait(0.2)
                                end
                                waitTime = 0.1
                            else
                                if (hrp.Position - (safeSpotPos + Vector3.new(0, 5, 0))).Magnitude > 10 then
                                    hrp.CFrame = safePart.CFrame + Vector3.new(0, 5, 0)
                                end
                                waitTime = 0.5
                            end

                        -- 3. TICKET FARM
                        elseif currentMode == "Ticket" then
                            local ticketsFolder = workspace:FindFirstChild("Game")
                                and workspace.Game:FindFirstChild("Effects")
                                and workspace.Game.Effects:FindFirstChild("Tickets")

                            if ticketsFolder then
                                local activeTickets = ticketsFolder:GetChildren()
                                if #activeTickets > 0 then
                                    if not currentTicket or not currentTicket.Parent then
                                        currentTicket = activeTickets[1]
                                        ticketProcessedTime = tick()
                                    end

                                    if currentTicket and currentTicket.Parent then
                                        local ticketPart = currentTicket:FindFirstChild("HumanoidRootPart")
                                            or (currentTicket:IsA("BasePart") and currentTicket)
                                        if ticketPart then
                                            local targetPosition = ticketPart.Position + Vector3.new(0, 15, 0)
                                            hrp.CFrame = CFrame.new(targetPosition)

                                            if tick() - ticketProcessedTime > 0.1 then
                                                hrp.CFrame = ticketPart.CFrame
                                            end
                                        else
                                            currentTicket = nil
                                        end
                                    else
                                        hrp.CFrame = safePart.CFrame + Vector3.new(0, 3, 0)
                                        currentTicket = nil
                                    end
                                else
                                    hrp.CFrame = safePart.CFrame + Vector3.new(0, 3, 0)
                                    currentTicket = nil
                                end
                            else
                                hrp.CFrame = safePart.CFrame + Vector3.new(0, 3, 0)
                                currentTicket = nil
                            end
                            waitTime = 0.1

                        -- 4. AFK FARM (Auto Win)
                        elseif currentMode == "AFK" then
                            if (hrp.Position - (safeSpotPos + Vector3.new(0, 5, 0))).Magnitude > 5 then
                                hrp.CFrame = safePart.CFrame + Vector3.new(0, 3, 0)
                            end
                            waitTime = 1.0
                        end
                    end
                end
                task.wait(waitTime)
            end
        end)
    end

    return {
        SetMode = function(m)
            currentMode = m
            if m ~= "None" then
                startMasterLoop()
            end
        end,
        GetMode = function()
            return currentMode
        end,
    }
end)()

	-- ========================================================================== --
	--                         PLAYER ADJUSTMENTS MODULE                          --
	-- ========================================================================== --

	local PlayerAdjustmentsModule = (function()
		local currentSettings = {
			Speed = 1500,
			JumpCap = 1,
			AirStrafeAcceleration = 187,
		}

		local applyMode = "Not Optimized" -- atau "Optimized"

		-- Required fields untuk deteksi movement tables
		local requiredFields = {
			"Friction",
			"AirStrafeAcceleration",
			"JumpHeight",
			"RunDeaccel",
			"JumpSpeedMultiplier",
			"JumpCap",
			"SprintCap",
			"WalkSpeedMultiplier",
			"BhopEnabled",
			"Speed",
			"AirAcceleration",
			"RunAccel",
			"SprintAcceleration",
		}

		-- Check apakah table punya semua field yang dibutuhkan
		local function hasAllFields(tbl)
			if type(tbl) ~= "table" then
				return false
			end

			for _, field in ipairs(requiredFields) do
				if rawget(tbl, field) == nil then
					return false
				end
			end

			return true
		end

		-- Cari semua movement config tables di game
		local function getConfigTables()
			local tables = {}

			for _, obj in ipairs(getgc(true)) do
				local success, result = pcall(function()
					if hasAllFields(obj) then
						return obj
					end
				end)

				if success and result then
					table.insert(tables, result)
				end
			end

			return tables
		end

		-- Apply callback ke semua tables
		local function applyToTables(callback)
			local targets = getConfigTables()

			if #targets == 0 then
				Warning("Player Settings", "No config tables found!", 2)
				return
			end

			if applyMode == "Optimized" then
				-- Optimized: batch apply dengan delay
				task.spawn(function()
					for i, tableObj in ipairs(targets) do
						if tableObj and typeof(tableObj) == "table" then
							pcall(callback, tableObj)
						end

						-- Delay setiap 3 tables
						if i % 3 == 0 then
							task.wait()
						end
					end
				end)
			else
				-- Not Optimized: langsung apply semua
				for i, tableObj in ipairs(targets) do
					if tableObj and typeof(tableObj) == "table" then
						pcall(callback, tableObj)
					end
				end
			end
		end

		-- Set speed
		local function setSpeed(speed)
			local val = tonumber(speed)
			if val and val >= 1450 and val <= 100000000 then
				currentSettings.Speed = val

				applyToTables(function(obj)
					obj.Speed = val
				end)

				Success("Player Speed", "Set to: " .. val, 1)
				return true
			else
				Error("Player Speed", "Value must be between 1450 and 100000000", 2)
				return false
			end
		end

		-- Set jump cap
		local function setJumpCap(cap)
			local val = tonumber(cap)
			if val and val >= 0.1 and val <= 5000000 then
				currentSettings.JumpCap = val

				applyToTables(function(obj)
					obj.JumpCap = val
				end)

				Success("Jump Cap", "Set to: " .. val, 1)
				return true
			else
				Error("Jump Cap", "Value must be between 0.1 and 5000000", 2)
				return false
			end
		end

		-- Set air strafe acceleration
		local function setStrafeAccel(accel)
			local val = tonumber(accel)
			if val and val >= 1 and val <= 1000000000 then
				currentSettings.AirStrafeAcceleration = val

				applyToTables(function(obj)
					obj.AirStrafeAcceleration = val
				end)

				Success("Strafe Accel", "Set to: " .. val, 1)
				return true
			else
				Error("Strafe Accel", "Value must be between 1 and 1000000000", 2)
				return false
			end
		end

		-- Set apply mode
		local function setApplyMode(mode)
			applyMode = mode
			Info("Apply Mode", "Changed to: " .. mode, 1)
		end

		return {
			SetSpeed = setSpeed,
			SetJumpCap = setJumpCap,
			SetStrafeAccel = setStrafeAccel,
			SetApplyMode = setApplyMode,
			GetCurrentSettings = function()
				return currentSettings
			end,
			GetApplyMode = function()
				return applyMode
			end,
		}
	end)()

	-- ========================================================================== --
	--                         JUMP POWER SYSTEM                                  --
	-- ========================================================================== --

	local JumpPowerModule = (function()
		local jumpPowerValue = 3.5
		local maxJumps = math.huge
		local currentJumpCount = 0
		local jumpHumanoid = nil
		local jumpRootPart = nil

		local stateConnection = nil
		local jumpConnection = nil
		local charConnection = nil

		-- Setup jump system untuk character
		local function setupCharacter(character)
			if not character then
				return
			end

			-- Cleanup old connections
			if stateConnection then
				stateConnection:Disconnect()
				stateConnection = nil
			end
			if jumpConnection then
				jumpConnection:Disconnect()
				jumpConnection = nil
			end

			task.wait(0.5)

			jumpHumanoid = character:FindFirstChild("Humanoid")
			jumpRootPart = character:FindFirstChild("HumanoidRootPart")

			if not jumpHumanoid or not jumpRootPart then
				return
			end

			currentJumpCount = 0

			-- Reset jump count saat landing
			stateConnection = jumpHumanoid.StateChanged:Connect(function(oldState, newState)
				if newState == Enum.HumanoidStateType.Landed then
					currentJumpCount = 0
				end
			end)

			-- Handle jumping
			jumpConnection = jumpHumanoid.Jumping:Connect(function(isJumping)
				if isJumping and currentJumpCount < maxJumps then
					currentJumpCount = currentJumpCount + 1
					jumpHumanoid.JumpHeight = jumpPowerValue

					-- Apply impulse for multi-jump
					if currentJumpCount > 1 and jumpRootPart then
						jumpRootPart:ApplyImpulse(Vector3.new(0, jumpPowerValue * jumpRootPart.Mass, 0))
					end
				end
			end)
		end

		-- Initialize
		local function initialize()
			-- Setup current character
			if player.Character then
				task.spawn(function()
					setupCharacter(player.Character)
				end)
			end

			-- Setup for future characters
			charConnection = player.CharacterAdded:Connect(function(newChar)
				setupCharacter(newChar)
			end)
		end

		-- Set jump power value
		local function setJumpPower(value)
			local val = tonumber(value)
			if val and val > 0 and val <= 1000 then
				jumpPowerValue = val

				if jumpHumanoid then
					jumpHumanoid.JumpHeight = val
				end

				Success("Jump Power", "Set to: " .. val, 1)
				return true
			else
				Error("Jump Power", "Value must be between 0.1 and 1000", 2)
				return false
			end
		end

		-- Cleanup
		local function cleanup()
			if stateConnection then
				stateConnection:Disconnect()
			end
			if jumpConnection then
				jumpConnection:Disconnect()
			end
			if charConnection then
				charConnection:Disconnect()
			end
		end

		-- Auto-initialize
		initialize()

		return {
			SetJumpPower = setJumpPower,
			GetJumpPower = function()
				return jumpPowerValue
			end,
			Cleanup = cleanup,
		}
	end)()

	-- ========================================================================== --
	--                         FOV ADJUSTMENT MODULE                              --
	-- ========================================================================== --

	local FOVModule = (function()
		local changeSettingRemote =
			ReplicatedStorage:WaitForChild("Events"):WaitForChild("Data"):WaitForChild("ChangeSetting")
		local updatedEvent = ReplicatedStorage:WaitForChild("Modules")
			:WaitForChild("Client")
			:WaitForChild("Settings")
			:WaitForChild("Updated")

		local function setFOV(fov)
			local num = tonumber(fov)
			if num and num >= 1 and num <= 1000 then
				pcall(function()
					changeSettingRemote:InvokeServer(2, num)
					updatedEvent:Fire(2, num)
				end)

				Success("FOV", "Set to: " .. num, 1)
				return true
			else
				Error("FOV", "Value must be between 1 and 1000", 2)
				return false
			end
		end

		return {
			SetFOV = setFOV,
		}
	end)()

	-- ========================================================================== --
	--                         TELEPORT MODULE (EXTERNAL)                          --
	-- ========================================================================== --

	local TeleportModule = (function()
		local TELEPORT_MODULE_URL =
			"https://raw.githubusercontent.com/dapabulo78/encluarz/refs/heads/main/Scripts/556118d919567f89.lua"

		local moduleData = nil
		local loadError = nil
		local lastLoadTime = nil
		local currentMap = "Unknown"
		local mapCheckConnection = nil
		local isStartup = true

		local function detectCurrentMap()
			local gameFolder = workspace:FindFirstChild("Game")
			if gameFolder then
				local mapFolder = gameFolder:FindFirstChild("Map")
				if mapFolder then
					local mapName = mapFolder:GetAttribute("MapName")
					if mapName and mapName ~= "" then
						return mapName
					end
				end
			end
			return "Unknown"
		end

		local function handleMapChange(newMap)
			if isStartup then
				return
			end

			if newMap == "Unknown" then
				Warning("Map Detection", "Could not detect current map!", 3)
				return
			end

			if not moduleData then
				return
			end

			if moduleData and moduleData.HasMapData and moduleData.HasMapData(newMap) then
				local mapCount = moduleData.GetMapCount and moduleData.GetMapCount() or 0
				Success("Map Detected", newMap .. " (" .. mapCount .. " maps available)", 3)
			else
				if moduleData then
					Warning("Map Not Found", newMap .. " - Please refresh database", 4)
				end
			end
		end

		local function startMapMonitoring()
			if mapCheckConnection then
				mapCheckConnection:Disconnect()
			end

			mapCheckConnection = RunService.Heartbeat:Connect(function()
				local newMap = detectCurrentMap()
				if newMap ~= currentMap then
					currentMap = newMap
					handleMapChange(newMap)
				end
			end)
		end

		local function stopMapMonitoring()
			if mapCheckConnection then
				mapCheckConnection:Disconnect()
				mapCheckConnection = nil
			end
		end

		local function loadFromGitHub()
			loadError = nil
			local success, result = pcall(function()
				print("Loading Teleport Module")
				local script = game:HttpGet(TELEPORT_MODULE_URL)
				return loadstring(script)()
			end)

			if success and result then
				moduleData = result
				lastLoadTime = os.time()

				currentMap = detectCurrentMap()
				handleMapChange(currentMap)

				print("Teleport Module loaded! Maps: " .. (result.GetMapCount and result.GetMapCount() or "?"))
				return true
			else
				loadError = tostring(result)
				warn("❌ Failed to load Teleport Module:", loadError)
				Error("Teleport Module", "Failed to load: " .. loadError, 5)
				return false
			end
		end

		loadFromGitHub()
		startMapMonitoring()

		task.delay(3, function()
			isStartup = false
		end)

		game:GetService("Players").PlayerRemoving:Connect(function(leavingPlayer)
			if leavingPlayer == player then
				stopMapMonitoring()
			end
		end)

		local function validateCharacter()
			local char = player.Character
			if not char then
				Error("Teleport", "Character not found!", 2)
				return nil, nil
			end

			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then
				Error("Teleport", "HumanoidRootPart not found!", 2)
				return nil, nil
			end

			return char, hrp
		end

		local function safeTeleport(hrp, targetPosition, filterInstances)
			filterInstances = filterInstances or {}
			local teleportPos = targetPosition + Vector3.new(0, 5, 0)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = filterInstances
			raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

			local ray = workspace:Raycast(teleportPos, Vector3.new(0, -10, 0), raycastParams)
			if ray then
				teleportPos = ray.Position + Vector3.new(0, 3, 0)
			end

			hrp.CFrame = CFrame.new(teleportPos)
			return true
		end

		local function getCurrentMap()
			return currentMap
		end

		local function placeTeleporter(cframe)
			if not cframe then
				Error("Teleport", "Invalid teleporter position!", 2)
				return false
			end

			task.spawn(function()
				pcall(function()
					local args = { [1] = 0, [2] = 16 }
					ReplicatedStorage:WaitForChild("Events")
						:WaitForChild("Character")
						:WaitForChild("ToolAction")
						:FireServer(unpack(args))
				end)

				task.wait(1)

				pcall(function()
					local args2 = { [1] = 1, [2] = { [1] = "Teleporter", [2] = cframe } }
					ReplicatedStorage:WaitForChild("Events")
						:WaitForChild("Character")
						:WaitForChild("ToolAction")
						:FireServer(unpack(args2))
				end)

				task.wait(1)

				pcall(function()
					local args3 = { [1] = 0, [2] = 15 }
					ReplicatedStorage:WaitForChild("Events")
						:WaitForChild("Character")
						:WaitForChild("ToolAction")
						:FireServer(unpack(args3))
				end)

				Success("Teleporter Placed", "Teleporter successfully placed!", 2)
			end)

			return true
		end

		return {
			IsLoaded = function()
				return moduleData ~= nil
			end,
			GetError = function()
				return loadError
			end,
			GetLastLoad = function()
				return lastLoadTime
			end,
			GetCurrentMap = getCurrentMap,

			Refresh = function()
				stopMapMonitoring()
				local success = loadFromGitHub()
				startMapMonitoring()
				if success then
					Success(
						"Teleport Module",
						"Refreshed successfully! Maps: " .. (moduleData.GetMapCount and moduleData.GetMapCount() or "?"),
						3
					)
				else
					Error("Teleport Module", "Refresh failed: " .. (loadError or "Unknown error"), 5)
				end
				return success
			end,

			HasMapData = function(mapName)
				return moduleData and moduleData.HasMapData and moduleData.HasMapData(mapName) or false
			end,
			GetMapSpot = function(mapName, spotType)
				return moduleData and moduleData.GetMapSpot and moduleData.GetMapSpot(mapName, spotType) or nil
			end,
			GetAllMapNames = function()
				return moduleData and moduleData.GetAllMapNames and moduleData.GetAllMapNames() or {}
			end,
			GetMapCount = function()
				return moduleData and moduleData.GetMapCount and moduleData.GetMapCount() or 0
			end,
			GetLastUpdate = function()
				return moduleData and moduleData.GetLastUpdate and moduleData.GetLastUpdate() or "Unknown"
			end,

			TeleportPlayer = function(spotType)
				if not moduleData then
					Error("Teleport", "Module not loaded! Click Refresh first.", 3)
					return false
				end

				local char, hrp = validateCharacter()
				if not char or not hrp then
					return false
				end

				local mapName = currentMap
				if mapName == "Unknown" then
					Error("Teleport", "Could not detect map name!", 2)
					return false
				end

				if not moduleData.HasMapData(mapName) then
					Error("Teleport", "Map '" .. mapName .. "' not in database! Click Refresh to update.", 4)
					return false
				end

				local cframe = moduleData.GetMapSpot(mapName, spotType)
				if not cframe then
					Error("Teleport", "No " .. spotType .. " spot found for " .. mapName, 3)
					return false
				end

				Info("Teleporting", "Teleporting to " .. spotType .. " for " .. mapName .. "...", 2)
				return safeTeleport(hrp, cframe.Position, { char })
			end,

			PlaceTeleporter = function(spotType)
				if not moduleData then
					Error("Teleport", "Module not loaded! Click Refresh first.", 3)
					return false
				end

				local mapName = currentMap
				if mapName == "Unknown" then
					Error("Teleport", "Could not detect map name!", 2)
					return false
				end

				if not moduleData.HasMapData(mapName) then
					Error("Teleport", "Map '" .. mapName .. "' not in database! Click Refresh to update.", 4)
					return false
				end

				local cframe = moduleData.GetMapSpot(mapName, spotType)
				if not cframe then
					Error("Teleport", "No " .. spotType .. " spot found for " .. mapName, 3)
					return false
				end

				Info("Placing Teleporter", "Placing " .. spotType .. " teleporter for " .. mapName .. "...", 2)
				return placeTeleporter(cframe)
			end,
		}
	end)()

	-- ========================================================================== --
	--                         TELEPORT FEATURES MODULE                           --
	-- ========================================================================== --

	local TeleportFeaturesModule = (function()
		local function validateCharacter()
			local success, char = pcall(function()
				return player.Character
			end)

			if not success or not char then
				Error("Teleport", "Character not found!", 2)
				return nil, nil
			end

			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then
				Error("Teleport", "HumanoidRootPart not found!", 2)
				return nil, nil
			end

			return char, hrp
		end

		local function safeTeleport(hrp, targetPosition, filterInstances)
			filterInstances = filterInstances or {}
			local teleportPos = targetPosition + Vector3.new(0, 5, 0)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = filterInstances
			raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

			local raySuccess, ray = pcall(function()
				return workspace:Raycast(teleportPos, Vector3.new(0, -10, 0), raycastParams)
			end)

			if raySuccess and ray then
				teleportPos = ray.Position + Vector3.new(0, 3, 0)
			end

			local setSuccess, setErr = pcall(function()
				hrp.CFrame = CFrame.new(teleportPos)
			end)

			return setSuccess
		end

		local function findNearestTicketInternal()
			local success, gameFolder = pcall(function()
				return workspace:FindFirstChild("Game")
			end)

			if not success or not gameFolder then
				return nil
			end

			local effects = gameFolder:FindFirstChild("Effects")
			if not effects then
				return nil
			end

			local tickets = effects:FindFirstChild("Tickets")
			if not tickets then
				return nil
			end

			local char = player.Character
			if not char or not char:FindFirstChild("HumanoidRootPart") then
				return nil
			end

			local hrp = char.HumanoidRootPart
			local nearestTicket = nil
			local nearestDistance = math.huge

			for _, ticket in pairs(tickets:GetChildren()) do
				if ticket:IsA("BasePart") or ticket:IsA("Model") then
					local ticketPart = ticket:IsA("Model") and ticket:FindFirstChild("HumanoidRootPart") or ticket
					if ticketPart and ticketPart:IsA("BasePart") then
						local distSuccess, dist = pcall(function()
							return (hrp.Position - ticketPart.Position).Magnitude
						end)
						if distSuccess and dist and dist < nearestDistance then
							nearestDistance = dist
							nearestTicket = ticketPart
						end
					end
				end
			end

			return nearestTicket
		end

		local function isPlayerDowned(pl)
			local success, result = pcall(function()
				if not pl or not pl.Character then
					return false
				end
				local char = pl.Character
				if char:GetAttribute("Downed") then
					return true
				end
				local hum = char:FindFirstChild("Humanoid")
				if hum and hum.Health <= 0 then
					return true
				end
				return false
			end)
			return success and result or false
		end

		local function findNearestDownedPlayer()
			local char, hrp = validateCharacter()
			if not char or not hrp then
				return nil
			end

			local nearestPlayer = nil
			local nearestDistance = math.huge

			for _, pl in pairs(Players:GetPlayers()) do
				if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
					if isPlayerDowned(pl) then
						local distSuccess, dist = pcall(function()
							return (hrp.Position - pl.Character.HumanoidRootPart.Position).Magnitude
						end)
						if distSuccess and dist and dist < nearestDistance then
							nearestDistance = dist
							nearestPlayer = pl
						end
					end
				end
			end

			return nearestPlayer, nearestDistance
		end

		local function getPlayerList()
			local playerNames = {}
			for _, pl in pairs(Players:GetPlayers()) do
				if pl ~= player then
					table.insert(playerNames, pl.Name)
				end
			end
			table.sort(playerNames)
			return #playerNames > 0 and playerNames or { "No players available" }
		end

		return {
			GetPlayerList = getPlayerList,
			TeleportToPlayer = function(playerName)
				if not playerName or playerName == "No players available" then
					Error("Teleport", "No player selected!", 2)
					return false
				end

				local char, hrp = validateCharacter()
				if not char or not hrp then
					return false
				end

				local targetPlayer = Players:FindFirstChild(playerName)
				if
					not targetPlayer
					or not targetPlayer.Character
					or not targetPlayer.Character:FindFirstChild("HumanoidRootPart")
				then
					Error("Teleport", playerName .. " not found or no character!", 2)
					return false
				end

				local targetHRP = targetPlayer.Character.HumanoidRootPart
				safeTeleport(hrp, targetHRP.Position, { char, targetPlayer.Character })
				Success("Teleport", "Teleported to " .. playerName, 2)
				return true
			end,
			TeleportToRandomPlayer = function()
				local char, hrp = validateCharacter()
				if not char or not hrp then
					return false
				end

				local players = {}
				for _, pl in pairs(Players:GetPlayers()) do
					if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
						table.insert(players, pl)
					end
				end

				if #players == 0 then
					Error("Teleport", "No other players found!", 2)
					return false
				end

				local randomPlayer = players[math.random(1, #players)]
				local targetHRP = randomPlayer.Character.HumanoidRootPart
				safeTeleport(hrp, targetHRP.Position, { char, randomPlayer.Character })
				Success("Teleport", "Teleported to " .. randomPlayer.Name, 2)
				return true
			end,
			TeleportToNearestDowned = function()
				local char, hrp = validateCharacter()
				if not char or not hrp then
					return false
				end

				local nearestPlayer, distance = findNearestDownedPlayer()
				if not nearestPlayer then
					Error("Teleport", "No downed players found!", 2)
					return false
				end

				local targetHRP = nearestPlayer.Character.HumanoidRootPart
				safeTeleport(hrp, targetHRP.Position, { char, nearestPlayer.Character })
				Success(
					"Teleport",
					"Teleported to " .. nearestPlayer.Name .. " (" .. math.floor(distance) .. " studs)",
					2
				)
				return true
			end,
			TeleportToRandomObjective = function()
				local char, hrp = validateCharacter()
				if not char or not hrp then
					return false
				end

				local objectives = {}
				local gameFolder = workspace:FindFirstChild("Game")
				if not gameFolder then
					Error("Teleport", "Game folder not found!", 2)
					return false
				end

				local mapFolder = gameFolder:FindFirstChild("Map")
				if not mapFolder then
					Error("Teleport", "Map folder not found!", 2)
					return false
				end

				local partsFolder = mapFolder:FindFirstChild("Parts")
				if not partsFolder then
					Error("Teleport", "Parts folder not found!", 2)
					return false
				end

				local objectivesFolder = partsFolder:FindFirstChild("Objectives")
				if not objectivesFolder then
					Error("Teleport", "Objectives folder not found!", 2)
					return false
				end

				for _, obj in pairs(objectivesFolder:GetChildren()) do
					if obj:IsA("Model") then
						local primaryPart = obj.PrimaryPart
						if not primaryPart then
							for _, part in pairs(obj:GetChildren()) do
								if part:IsA("BasePart") then
									primaryPart = part
									break
								end
							end
						end

						if primaryPart then
							table.insert(objectives, {
								Name = obj.Name,
								Part = primaryPart,
							})
						end
					end
				end

				if #objectives == 0 then
					Error("Teleport", "No objectives found!", 2)
					return false
				end

				local selectedObjective = objectives[math.random(1, #objectives)]
				safeTeleport(hrp, selectedObjective.Part.Position, { char })
				Success("Teleport", "Teleported to " .. selectedObjective.Name, 2)
				return true
			end,
			TeleportToNearestTicket = function()
				local char, hrp = validateCharacter()
				if not char or not hrp then
					return false
				end

				local ticket = findNearestTicketInternal()
				if not ticket then
					Error("Teleport", "No tickets found!", 2)
					return false
				end

				safeTeleport(hrp, ticket.Position, { char })
				Success("Teleport", "Teleported to nearest ticket!", 2)
				return true
			end,
		}
	end)()

	-- ========================================================================== --
	--                         SERVER UTILITIES MODULE                            --
	-- ========================================================================== --

	local ServerUtils = (function()
		local function getServerLink()
			return string.format("https://www.roblox.com/games/start?placeId=%d&jobId=%s", placeId, jobId)
		end

		local function joinServerByPlaceId(targetPlaceId, modeName)
			local success, servers = pcall(function()
				return HttpService:JSONDecode(
					game:HttpGet(
						"https://games.roblox.com/v1/games/"
							.. targetPlaceId
							.. "/servers/Public?sortOrder=Asc&limit=100"
					)
				)
			end)

			if not success or not servers or not servers.data then
				Error("Join Failed", "Could not fetch " .. modeName .. " servers!", 3)
				return
			end

			local availableServers = {}
			for _, server in ipairs(servers.data) do
				if server.playing < server.maxPlayers then
					table.insert(availableServers, server)
				end
			end

			if #availableServers == 0 then
				Error("Join Failed", "No available " .. modeName .. " servers found!", 3)
				return
			end

			table.sort(availableServers, function(a, b)
				return a.playing > b.playing
			end)
			local targetServer = availableServers[1]

			Library:Notify({
				Title = "Joining " .. modeName,
				Description = "Teleporting to server with "
					.. targetServer.playing
					.. "/"
					.. targetServer.maxPlayers
					.. " players",
				Time = 3,
			})

			local teleportSuccess, teleportErr = pcall(function()
				TeleportService:TeleportToPlaceInstance(targetPlaceId, targetServer.id, player)
			end)

			if not teleportSuccess then
				Error("Join Failed", "Teleport error: " .. tostring(teleportErr), 3)
			end
		end

		local function serverHop(minPlayers)
			minPlayers = minPlayers or 5
			local success, servers = pcall(function()
				return HttpService:JSONDecode(
					game:HttpGet(
						"https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
					)
				)
			end)

			if not success or not servers or not servers.data then
				Error("Server Hop", "Failed to fetch servers!", 3)
				return false
			end

			local filteredServers = {}
			for _, server in ipairs(servers.data) do
				if server.playing >= minPlayers and server.playing < server.maxPlayers then
					table.insert(filteredServers, server)
				end
			end

			if #filteredServers == 0 then
				Info("Server Hop", "No servers with " .. minPlayers .. "+ players", 3)
				return false
			end

			local randomServer = filteredServers[math.random(1, #filteredServers)]

			local teleportSuccess, teleportErr = pcall(function()
				TeleportService:TeleportToPlaceInstance(placeId, randomServer.id, player)
			end)

			if not teleportSuccess then
				Error("Server Hop", "Teleport failed: " .. tostring(teleportErr), 3)
				return false
			end

			return true
		end

		local function hopToSmallestServer()
			local success, servers = pcall(function()
				return HttpService:JSONDecode(
					game:HttpGet(
						"https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
					)
				)
			end)

			if not success or not servers or not servers.data then
				Error("Server Hop", "Failed to fetch servers!", 3)
				return false
			end

			table.sort(servers.data, function(a, b)
				return a.playing < b.playing
			end)
			if not servers.data[1] then
				Error("Server Hop", "No servers found!", 3)
				return false
			end

			local teleportSuccess, teleportErr = pcall(function()
				TeleportService:TeleportToPlaceInstance(placeId, servers.data[1].id, player)
			end)

			if not teleportSuccess then
				Error("Server Hop", "Teleport failed: " .. tostring(teleportErr), 3)
				return false
			end

			return true
		end

		local function joinLowestServer(targetPlaceId, modeName)
			local success, servers = pcall(function()
				return HttpService:JSONDecode(
					game:HttpGet(
						"https://games.roblox.com/v1/games/"
							.. targetPlaceId
							.. "/servers/Public?sortOrder=Asc&limit=100"
					)
				)
			end)

			if not success or not servers or not servers.data then
				Error("Join Failed", "Could not fetch " .. modeName .. " servers!", 3)
				return
			end

			local availableServers = {}
			for _, server in ipairs(servers.data) do
				if server.playing < server.maxPlayers then
					table.insert(availableServers, server)
				end
			end

			if #availableServers == 0 then
				Error("Join Failed", "No available " .. modeName .. " servers found!", 3)
				return
			end

			table.sort(availableServers, function(a, b)
				return a.playing < b.playing
			end)
			local targetServer = availableServers[1]

			Library:Notify({
				Title = "Joining " .. modeName,
				Description = "Teleporting to server with "
					.. targetServer.playing
					.. "/"
					.. targetServer.maxPlayers
					.. " players",
				Time = 3,
			})

			local teleportSuccess, teleportErr = pcall(function()
				TeleportService:TeleportToPlaceInstance(targetPlaceId, targetServer.id, player)
			end)

			if not teleportSuccess then
				Error("Join Failed", "Teleport error: " .. tostring(teleportErr), 3)
			end
		end

		return {
			GetServerLink = getServerLink,
			JoinServerByPlaceId = joinServerByPlaceId,
			JoinLowestServer = joinLowestServer,
			ServerHop = serverHop,
			HopToSmallestServer = hopToSmallestServer,
		}
	end)()

	-- ========================================================================== --
	--                         AUTO PLACE TELEPORTER SYSTEM                       --
	-- ========================================================================== --

	local autoPlaceTeleporterEnabled = false
	local autoPlaceTeleporterType = "Far"
	local gameStats = workspace:WaitForChild("Game"):WaitForChild("Stats")

	_G.AutoPlaceConnection = gameStats:GetAttributeChangedSignal("RoundStarted"):Connect(function()
		if not autoPlaceTeleporterEnabled then
			return
		end
		local roundStarted = gameStats:GetAttribute("RoundStarted")
		local roundsCompleted = gameStats:GetAttribute("RoundsCompleted") or 0
		if not roundStarted and roundsCompleted < 3 then
			task.spawn(function()
				task.wait(3)
				local character = player.Character or player.CharacterAdded:Wait()
				character:WaitForChild("HumanoidRootPart")
				task.wait(1)
				TeleportModule.PlaceTeleporter(autoPlaceTeleporterType)
				Info("Auto Place", "Round " .. roundsCompleted .. " done", 2)
			end)
		end
	end)

	-- ========================================================================== --
	--                         NEW FEATURES MODULES                               --
	-- ========================================================================== --

	-- ANTI-AFK MODULE
	local AntiAFKModule = (function()
		local connection = nil
		local VU = game:GetService("VirtualUser")

		return {
			Start = function()
				if connection then
					return
				end
				-- Event Idled dipicu saat player tidak memberikan input selama 2 menit (internal)
				connection = player.Idled:Connect(function()
					-- Simulasi klik/input agar Roblox menganggap kita masih aktif
					VU:CaptureController()
					VU:ClickButton2(Vector2.new())
					print("Anti-AFK: Input simulated to prevent idle kick.")
				end)
				Success("Anti-AFK", "Anti-AFK Enabled (No Kick)", 2)
			end,
			Stop = function()
				if connection then
					connection:Disconnect()
					connection = nil
				end
				Info("Anti-AFK", "Anti-AFK Disabled", 2)
			end,
			IsEnabled = function()
				return connection ~= nil
			end,
		}
	end)()

	-- NOCLIP MODULE
	local NoclipModule = (function()
		local enabled = false
		local connection = nil

		local function toggleNoclip(state)
			enabled = state

			if enabled then
				if connection then
					pcall(function()
						connection:Disconnect()
					end)
				end

				connection = RunService.Stepped:Connect(function()
					local character = player.Character
					if character then
						for _, part in pairs(character:GetDescendants()) do
							if part:IsA("BasePart") and part.CanCollide then
								pcall(function()
									part.CanCollide = false
								end)
							end
						end
					end
				end)
			else
				if connection then
					pcall(function()
						connection:Disconnect()
					end)
					connection = nil
				end

				local character = player.Character
				if character then
					for _, part in pairs(character:GetDescendants()) do
						if part:IsA("BasePart") then
							pcall(function()
								part.CanCollide = true
							end)
						end
					end
				end
			end
		end

		return {
			Start = function()
				toggleNoclip(true)
			end,
			Stop = function()
				toggleNoclip(false)
			end,
			IsEnabled = function()
				return enabled
			end,
			OnCharacterAdded = function()
				if enabled then
					task.wait(0.5)
					toggleNoclip(false)
					task.wait(0.1)
					toggleNoclip(true)
				end
			end,
		}
	end)()

	-- EASY TRIMP SYSTEM (BOUNCE + MOMENTUM GABUNGAN)
	local EasyTrimpModule = (function()
		local bounceEnabled = false
		local momentumEnabled = false
		local mainTask = nil
		local pushForce = nil

		-- SEMUA SETTING (Lama + Baru)
		local settings = {
			bouncePower = 100, -- Dari Bounce
			groundDistance = 6, -- Dari Bounce (YANG TADI TERHAPUS)
			baseSpeed = 50, -- Dari Momentum
			extraSpeed = 100, -- Dari Momentum
			floorDrop = 0, -- Dari Momentum
		}

		local currentSpeed = settings.baseSpeed
		local lastTick = tick()
		local airTick = 0
		local airborne = false

		-- Helper: Ambil Speedometer Asli Game
		local function getEvadeMeter()
			local s, r = pcall(function()
				return player.PlayerGui.Shared.HUD.Overlay.Default.CharacterInfo.Item.Speedometer.Players
			end)
			return s and r or nil
		end

		local function updateLoop()
			while bounceEnabled or momentumEnabled do
				local dt = tick() - lastTick
				lastTick = tick()

				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChild("Humanoid")

				if root and hum then
					local inAir = hum.FloorMaterial == Enum.Material.Air
					local spdDisplay = getEvadeMeter()

					-- [FITUR 1: AUTO BOUNCE LOGIC]
					if bounceEnabled and root.Velocity.Y < 0 then
						local rayOrigin = root.Position
						local rayDirection = Vector3.new(0, -settings.groundDistance, 0)
						local rayParams = RaycastParams.new()
						rayParams.FilterDescendantsInstances = { char }
						rayParams.FilterType = Enum.RaycastFilterType.Blacklist

						local ray = workspace:Raycast(rayOrigin, rayDirection, rayParams)
						if ray then
							root.Velocity = Vector3.new(root.Velocity.X, settings.bouncePower, root.Velocity.Z)
						end
					end

					-- [FITUR 2: MOMENTUM LOGIC]
					if momentumEnabled then
						if airborne and not inAir then
							currentSpeed = math.max(settings.baseSpeed - settings.floorDrop, currentSpeed - 10)
						end
						airborne = inAir

						if inAir then
							airTick = airTick + dt
							while airTick >= 0.04 do
								airTick = airTick - 0.04
								local add = math.max(0.1, 2.5 * (0.04 / 1))
								currentSpeed = math.min(settings.baseSpeed + settings.extraSpeed, currentSpeed + add)
							end
						else
							airTick = 0
							currentSpeed = math.max(settings.baseSpeed - settings.floorDrop, currentSpeed - (2.5 * dt))
						end

						-- Apply dorongan BodyVelocity (Forward Momentum)
						if pushForce then
							pushForce:Destroy()
						end
						local look = workspace.CurrentCamera.CFrame.LookVector
						local moveDir = Vector3.new(look.X, 0, look.Z)
						if moveDir.Magnitude > 0 then
							moveDir = moveDir.Unit
						end

						local bv = Instance.new("BodyVelocity")
						bv.Name = "TrimpMomentumPush"
						bv.Velocity = moveDir * currentSpeed
						bv.MaxForce = Vector3.new(4e5, 0, 4e5)
						bv.P = 1250
						bv.Parent = root
						game:GetService("Debris"):AddItem(bv, 0.1)
						pushForce = bv

						if spdDisplay then
							spdDisplay.Text = tostring(math.floor(currentSpeed * 10) / 10)
						end
					end
				end
				task.wait()
			end
		end

		-- Fungsi Kontrol Task
		local function checkTask()
			if bounceEnabled or momentumEnabled then
				if not mainTask then
					lastTick = tick()
					mainTask = task.spawn(updateLoop)
				end
			else
				if mainTask then
					task.cancel(mainTask)
					mainTask = nil
				end
				if pushForce then
					pushForce:Destroy()
					pushForce = nil
				end
				currentSpeed = settings.baseSpeed
			end
		end

		return {
			ToggleBounce = function(state)
				bounceEnabled = state
				checkTask()
			end,
			ToggleMomentum = function(state)
				momentumEnabled = state
				checkTask()
			end,
			SetPower = function(v)
				settings.bouncePower = v
			end,
			SetDist = function(v)
				settings.groundDistance = v
			end,
			SetBase = function(v)
				settings.baseSpeed = v
			end,
			SetMax = function(v)
				settings.extraSpeed = v
			end,
			SetDrop = function(v)
				settings.floorDrop = v
			end,
			StopAll = function()
				bounceEnabled = false
				momentumEnabled = false
				checkTask()
			end,
			IsEnabled = function()
				return bounceEnabled or momentumEnabled
			end,
		}
	end)()

	-- BUG EMOTE MODULE
	local BugEmoteModule = (function()
		local enabled = false
		local connection = nil

		local function updateSit()
			if not enabled then
				return
			end

			local character = player.Character
			if not character then
				return
			end

			local humanoid = character:FindFirstChild("Humanoid")

			if not humanoid then
				local gamePlayers = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
				if gamePlayers then
					local playerModel = gamePlayers:FindFirstChild(player.Name)
					if playerModel then
						humanoid = playerModel:FindFirstChild("Humanoid")
					end
				end
			end

			if humanoid then
				pcall(function()
					humanoid.Sit = true
				end)
			end
		end

		local function start()
			if enabled then
				return
			end
			enabled = true

			if connection then
				pcall(function()
					connection:Disconnect()
				end)
			end

			connection = RunService.Heartbeat:Connect(updateSit)
			updateSit()
			Success("Bug Emote", "Force sit enabled", 2)
		end

		local function stop()
			if not enabled then
				return
			end
			enabled = false

			if connection then
				pcall(function()
					connection:Disconnect()
				end)
				connection = nil
			end

			local character = player.Character
			if character then
				local humanoid = character:FindFirstChild("Humanoid")
				if not humanoid then
					local gamePlayers = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
					if gamePlayers then
						local playerModel = gamePlayers:FindFirstChild(player.Name)
						if playerModel then
							humanoid = playerModel:FindFirstChild("Humanoid")
						end
					end
				end
				if humanoid then
					pcall(function()
						humanoid.Sit = false
					end)
				end
			end

			Info("Bug Emote", "Disabled", 2)
		end

		return {
			Start = start,
			Stop = stop,
			IsEnabled = function()
				return enabled
			end,
			OnCharacterAdded = function()
				if enabled then
					task.wait(1)
					updateSit()
				end
			end,
		}
	end)()

	-- ========================================================================== --
	--                         REMOVE BARRIERS MODULE                             --
	-- ========================================================================== --
	local RemoveBarriersModule = (function()
		local function createMobileBtn(name, text, posY, cb)
			local sg = Instance.new("ScreenGui")
			sg.Name = name
			sg.ResetOnSpawn = false
			sg.Enabled = false
			pcall(function()
				sg.Parent = gethui()
			end)
			if not sg.Parent then
				sg.Parent = game:GetService("CoreGui")
			end

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 110, 0, 30)
			btn.Position = UDim2.new(0, 10, 0, posY)
			btn.Font = Enum.Font.Code
			btn.TextSize = 12
			btn.Text = text
			btn.AutoButtonColor = false
			btn.Parent = sg

			local stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = btn

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 4)
			corner.Parent = btn

			local drag, ds, sp
			btn.InputBegan:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					drag = true
					ds = i.Position
					sp = btn.Position
				end
			end)
			btn.InputEnded:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					drag = false
				end
			end)
			game:GetService("UserInputService").InputChanged:Connect(function(i)
				if
					(i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch)
					and drag
				then
					btn.Position = UDim2.new(
						sp.X.Scale,
						sp.X.Offset + (i.Position.X - ds.X),
						sp.Y.Scale,
						sp.Y.Offset + (i.Position.Y - ds.Y)
					)
				end
			end)
			btn.MouseButton1Click:Connect(cb)

			return sg, btn, stroke
		end

		local enabled = false

		-- ==================== FLOATING MOBILE BTN ====================
		local mobileGui, mobileBtn, mobileStroke = createMobileBtn(
			"RBarriersMobileBtn",
			"R-Barrier: OFF",
			300,
			function()
				if Toggles and Toggles.RemoveBarriers then
					Toggles.RemoveBarriers:SetValue(not Toggles.RemoveBarriers.Value)
				end
			end
		)

		local function updateMobileBtn()
			if not mobileBtn then
				return
			end

			-- MENGAMBIL WARNA LANGSUNG DARI THEME MANAGER SECARA REAL-TIME
			local accent = (Options and Options.AccentColor and Options.AccentColor.Value)
				or (Library and typeof(Library.AccentColor) == "Color3" and Library.AccentColor)
				or Color3.fromRGB(115, 215, 85)
			local font = (Options and Options.FontColor and Options.FontColor.Value)
				or (Library and typeof(Library.FontColor) == "Color3" and Library.FontColor)
				or Color3.fromRGB(200, 200, 200)
			local main = (Options and Options.MainColor and Options.MainColor.Value)
				or (Library and typeof(Library.MainColor) == "Color3" and Library.MainColor)
				or Color3.fromRGB(20, 20, 20)
			local outline = (Options and Options.OutlineColor and Options.OutlineColor.Value)
				or (Library and typeof(Library.OutlineColor) == "Color3" and Library.OutlineColor)
				or Color3.fromRGB(45, 45, 45)

			mobileBtn.Text = enabled and "R-Barrier: ON" or "R-Barrier: OFF"
			mobileBtn.TextColor3 = enabled and accent or font
			mobileBtn.BackgroundColor3 = main
			mobileStroke.Color = outline
		end

		-- ZERO DELAY SYNC
		game:GetService("RunService").Heartbeat:Connect(function()
			if mobileGui and mobileGui.Parent then
				updateMobileBtn()
			end
		end)

		local function toggleBarriers(state)
			local success, invisParts = pcall(function()
				return workspace:FindFirstChild("Game")
					and workspace.Game:FindFirstChild("Map")
					and workspace.Game.Map:FindFirstChild("InvisParts")
			end)

			if not success or not invisParts then
				return
			end

			local objectsChanged = 0

			for _, obj in ipairs(invisParts:GetDescendants()) do
				if obj:IsA("BasePart") then
					pcall(function()
						obj.CanCollide = not state
						obj.CanQuery = not state
					end)
					objectsChanged = objectsChanged + 1
				end
			end

			if state then
				Success("Remove Barriers", "Barriers removed for " .. objectsChanged .. " objects", 2)
			else
				Info("Remove Barriers", "Barriers restored for " .. objectsChanged .. " objects", 2)
			end
		end

		return {
			Start = function()
				enabled = true
				toggleBarriers(true)
			end,
			Stop = function()
				enabled = false
				toggleBarriers(false)
			end,
			IsEnabled = function()
				return enabled
			end,
			SetMobileVisible = function(state)
				mobileGui.Enabled = state
			end,
			OnCharacterAdded = function()
				if enabled then
					task.wait(1)
					toggleBarriers(true)
				end
			end,
		}
	end)()

	-- ========================================================================== --
	--                         BARRIERS VISIBLE MODULE                            --
	-- ========================================================================== --
	local BarriersVisibleModule = (function()
		local function createMobileBtn(name, text, posY, cb)
			local sg = Instance.new("ScreenGui")
			sg.Name = name
			sg.ResetOnSpawn = false
			sg.Enabled = false
			pcall(function()
				sg.Parent = gethui()
			end)
			if not sg.Parent then
				sg.Parent = game:GetService("CoreGui")
			end

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 110, 0, 30)
			btn.Position = UDim2.new(0, 10, 0, posY)
			btn.Font = Enum.Font.Code
			btn.TextSize = 12
			btn.Text = text
			btn.AutoButtonColor = false
			btn.Parent = sg

			local stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = btn

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 4)
			corner.Parent = btn

			local drag, ds, sp
			btn.InputBegan:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					drag = true
					ds = i.Position
					sp = btn.Position
				end
			end)
			btn.InputEnded:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					drag = false
				end
			end)
			game:GetService("UserInputService").InputChanged:Connect(function(i)
				if
					(i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch)
					and drag
				then
					btn.Position = UDim2.new(
						sp.X.Scale,
						sp.X.Offset + (i.Position.X - ds.X),
						sp.Y.Scale,
						sp.Y.Offset + (i.Position.Y - ds.Y)
					)
				end
			end)
			btn.MouseButton1Click:Connect(cb)

			return sg, btn, stroke
		end

		local enabled = false
		local descendantConnection = nil
		local barrierColor = Color3.fromRGB(255, 0, 0)
		local barrierTransparency = 0

		-- ==================== FLOATING MOBILE BTN ====================
		local mobileGui, mobileBtn, mobileStroke = createMobileBtn(
			"VBarriersMobileBtn",
			"V-Barrier: OFF",
			340,
			function()
				if Toggles and Toggles.BarriersVisible then
					Toggles.BarriersVisible:SetValue(not Toggles.BarriersVisible.Value)
				end
			end
		)

		local function updateMobileBtn()
			if not mobileBtn then
				return
			end
			local accent = (Options and Options.AccentColor and Options.AccentColor.Value)
				or (Library and typeof(Library.AccentColor) == "Color3" and Library.AccentColor)
				or Color3.fromRGB(115, 215, 85)
			local font = (Options and Options.FontColor and Options.FontColor.Value)
				or (Library and typeof(Library.FontColor) == "Color3" and Library.FontColor)
				or Color3.fromRGB(200, 200, 200)
			local main = (Options and Options.MainColor and Options.MainColor.Value)
				or (Library and typeof(Library.MainColor) == "Color3" and Library.MainColor)
				or Color3.fromRGB(20, 20, 20)
			local outline = (Options and Options.OutlineColor and Options.OutlineColor.Value)
				or (Library and typeof(Library.OutlineColor) == "Color3" and Library.OutlineColor)
				or Color3.fromRGB(45, 45, 45)

			mobileBtn.Text = enabled and "V-Barrier: ON" or "V-Barrier: OFF"
			mobileBtn.TextColor3 = enabled and accent or font
			mobileBtn.BackgroundColor3 = main
			mobileStroke.Color = outline
		end

		-- ZERO DELAY SYNC
		game:GetService("RunService").Heartbeat:Connect(function()
			if mobileGui and mobileGui.Parent then
				updateMobileBtn()
			end
		end)

		local function setTransparency(transparent)
			local success, invisParts = pcall(function()
				return workspace:FindFirstChild("Game")
					and workspace.Game:FindFirstChild("Map")
					and workspace.Game.Map:FindFirstChild("InvisParts")
			end)

			if not success or not invisParts then
				return 0
			end

			local changed = 0

			if transparent then
				for _, obj in ipairs(invisParts:GetDescendants()) do
					pcall(function()
						if obj:IsA("BasePart") then
							obj.Transparency = barrierTransparency
							obj.Color = barrierColor
							obj.Material = Enum.Material.Neon
							changed = changed + 1
						elseif obj:IsA("Decal") then
							obj.Transparency = barrierTransparency
							changed = changed + 1
						end
					end)
				end
			else
				for _, obj in ipairs(invisParts:GetDescendants()) do
					pcall(function()
						if obj:IsA("BasePart") or obj:IsA("Decal") then
							obj.Transparency = 1
							if obj:IsA("BasePart") then
								obj.Color = Color3.fromRGB(255, 255, 255)
								obj.Material = Enum.Material.Plastic
							end
							changed = changed + 1
						end
					end)
				end
			end
			return changed
		end

		local function setupDescendantListener()
			if descendantConnection then
				pcall(function()
					descendantConnection:Disconnect()
				end)
			end

			local success, invisParts = pcall(function()
				return workspace:FindFirstChild("Game")
					and workspace.Game:FindFirstChild("Map")
					and workspace.Game.Map:FindFirstChild("InvisParts")
			end)

			if success and invisParts and enabled then
				descendantConnection = invisParts.DescendantAdded:Connect(function(obj)
					if enabled then
						task.wait(0.05)
						pcall(function()
							if obj:IsA("BasePart") then
								obj.Transparency = barrierTransparency
								obj.Color = barrierColor
								obj.Material = Enum.Material.Neon
							elseif obj:IsA("Decal") then
								obj.Transparency = barrierTransparency
							end
						end)
					end
				end)
			end
		end

		local function setColor(color)
			barrierColor = color
			if enabled then
				setTransparency(true)
			end
		end

		local function setTransparencyLevel(transparencyValue)
			barrierTransparency = transparencyValue
			if enabled then
				setTransparency(true)
			end
			return barrierTransparency
		end

		local function start()
			enabled = true
			local changed = setTransparency(true)
			setupDescendantListener()
			Success("Barriers Visible", "Made " .. changed .. " barriers visible", 2)
		end

		local function stop()
			enabled = false
			local changed = setTransparency(false)
			if descendantConnection then
				pcall(function()
					descendantConnection:Disconnect()
				end)
				descendantConnection = nil
			end
			Info("Barriers Visible", "Made " .. changed .. " barriers invisible", 2)
		end

		return {
			Start = start,
			Stop = stop,
			SetColor = setColor,
			SetTransparencyLevel = setTransparencyLevel,
			IsEnabled = function()
				return enabled
			end,
			SetMobileVisible = function(state)
				mobileGui.Enabled = state
			end,
			OnCharacterAdded = function()
				if enabled then
					task.wait(1)
					setTransparency(true)
				end
			end,
		}
	end)()

	-- GRAPPLEHOOK MODULE
	local GrapplehookModule = (function()
		local function enhanceGrappleHook()
			local success, result = pcall(function()
				local GrappleHook = require(ReplicatedStorage.Tools["GrappleHook"])

				if not GrappleHook then
					error("GrappleHook module not found")
				end

				local grappleTask = GrappleHook.Tasks[2]
				if not grappleTask then
					error("GrappleTask not found")
				end

				local shootMethod = grappleTask.Functions[1].Activations[1].Methods[1]
				if not shootMethod then
					error("Shoot method not found")
				end

				shootMethod.Info.Speed = 10000
				shootMethod.Info.Lifetime = 10.0
				shootMethod.Info.Gravity = Vector3.new(0, 0, 0)
				shootMethod.Info.SpreadIncrease = 0
				shootMethod.Info.Cooldown = 0.2

				grappleTask.MethodReferences.Projectile.Info.SpreadInfo.MaxSpread = 0
				grappleTask.MethodReferences.Projectile.Info.SpreadInfo.MinSpread = 0
				grappleTask.MethodReferences.Projectile.Info.SpreadInfo.ReductionRate = 100

				local checkMethod = grappleTask.AutomaticFunctions[1].Methods[1]
				if checkMethod then
					checkMethod.Info.Cooldown = 0.2
					checkMethod.CooldownInfo.TestCooldown = 0.2
				end

				-- KITA CUKUP SET CAP-NYA SAJA (Isi bensin Grapplehook)
				grappleTask.ResourceInfo.Cap = 24

				-- BARIS INI YANG DIHAPUS:
				-- grappleTask.ResourceInfo.Reserve = 24
				-- (Dengan menghapus baris Reserve, game tidak akan memunculkan "/ 24" dan ikon peluru)

				return true
			end)

			if success then
				Success("Grapplehook", "Enhanced successfully!", 2)
				return true
			else
				Error("Grapplehook", "Failed to enhance: " .. tostring(result), 3)
				warn("Grapplehook error details:", result)
				return false
			end
		end

		return {
			Execute = function()
				return enhanceGrappleHook()
			end,
		}
	end)()

	-- BREACHER MODULE
	local BreacherModule = (function()
		local function enhanceBreacher()
			local success, result = pcall(function()
				local Breacher = require(ReplicatedStorage.Tools.Breacher)

				if not Breacher then
					error("Breacher module not found")
				end

				local portalTask
				for i, task in ipairs(Breacher.Tasks) do
					if task.ResourceInfo and task.ResourceInfo.Type == "Clip" then
						portalTask = task
						break
					end
				end

				if not portalTask then
					portalTask = Breacher.Tasks[2]
				end

				portalTask.ResourceInfo.Cap = 80

				local blueShoot = portalTask.Functions[1].Activations[1].Methods[1]
				local yellowShoot = portalTask.Functions[2].Activations[1].Methods[1]

				blueShoot.Info.Range = 99999999
				yellowShoot.Info.Range = 99999999

				blueShoot.Info.SpreadIncrease = 0
				yellowShoot.Info.SpreadIncrease = 0

				portalTask.MethodReferences.Portal.Info.SpreadInfo.MaxSpread = 0
				portalTask.MethodReferences.Portal.Info.SpreadInfo.MinSpread = 0
				portalTask.MethodReferences.Portal.Info.SpreadInfo.ReductionRate = 100

				blueShoot.Info.Cooldown = 0.3
				yellowShoot.Info.Cooldown = 0.3

				blueShoot.CooldownInfo = {}
				yellowShoot.CooldownInfo = {}
				blueShoot.Requirements = {}
				yellowShoot.Requirements = {}

				Breacher.Actions.ADS.Enabled = false

				portalTask.Functions[1].Activations[1].CanHoldDown = true
				portalTask.Functions[2].Activations[1].CanHoldDown = true

				return true
			end)

			if success then
				Success("Breacher", "Portal Gun enhanced successfully!", 2)
				return true
			else
				Error("Breacher", "Failed to enhance: " .. tostring(result), 3)
				warn("Breacher error details:", result)
				return false
			end
		end

		return {
			Execute = function()
				return enhanceBreacher()
			end,
		}
	end)()

	-- SMOKE GRENADE MODULE
	local SmokeGrenadeModule = (function()
		local function enhanceSmokeGrenade()
			local success, result = pcall(function()
				local SmokeGrenade = require(ReplicatedStorage.Tools["SmokeGrenade"])

				if not SmokeGrenade then
					error("SmokeGrenade module not found")
				end

				SmokeGrenade.RequiresOwnedItem = false

				local throwMethod = SmokeGrenade.Tasks[1].Functions[1].Activations[1].Methods[1]

				throwMethod.ItemUseIncrement = { "SmokeGrenade", 999 }
				throwMethod.Info.Cooldown = 0.5
				throwMethod.Info.ThrowVelocity = 200

				SmokeGrenade.Tasks[1].Functions[1].Activations[1].CanHoldDown = true

				throwMethod.Info.SmokeDuration = 999
				throwMethod.Info.SmokeRadius = 100
				throwMethod.Info.FadeTime = 60

				local equipMethod = SmokeGrenade.Tasks[1].AutomaticFunctions[1].Methods[1]
				local unequipMethod = SmokeGrenade.Tasks[1].AutomaticFunctions[2].Methods[1]
				equipMethod.Info.Cooldown = 0.5
				unequipMethod.Info.Cooldown = 0.5

				throwMethod.CooldownInfo = {}

				return true
			end)

			if success then
				Success("Smoke Grenade", "Enhanced successfully!", 2)
				return true
			else
				Error("Smoke Grenade", "Failed to enhance: " .. tostring(result), 3)
				warn("Smoke Grenade error details:", result)
				return false
			end
		end

		return {
			Execute = function()
				return enhanceSmokeGrenade()
			end,
		}
	end)()

	-- STUN BATON MODULE
	local StunBatonModule = (function()
		local function enhanceStunBaton()
			local success, result = pcall(function()
				local StunBaton = require(ReplicatedStorage.Tools["StunBaton"])

				local task = StunBaton.Tasks[1]

				task.Functions[1].Activations[1].CanHoldDown = true
				task.Functions[1].Activations[2].CanHoldDown = true

				task.Functions[1].Activations[1].Methods[1].Info.LungeRange = 0
				task.Functions[1].Activations[2].Methods[1].Info.LungeRange = 0

				task.AutomaticFunctions[1].Methods[1].Info.Range = 999
				task.AutomaticFunctions[2].Methods[1].Info.Range = 999

				if task.Functions[1].Activations[2].Methods[1].Requirements then
					if task.Functions[1].Activations[2].Methods[1].Requirements.MeleeSuccess then
						task.Functions[1].Activations[2].Methods[1].Requirements.MeleeSuccess = nil
					end
				end

				task.AutomaticFunctions[1].Methods[1].Info.Cooldown = 0.1
				task.AutomaticFunctions[2].Methods[1].Info.Cooldown = 0.1
				task.Functions[1].Activations[1].Methods[1].Info.Cooldown = 0.1
				task.Functions[1].Activations[2].Methods[1].Info.Cooldown = 0.1

				task.Functions[1].Activations[1].Methods[1].Requirements = {}
				task.Functions[1].Activations[2].Methods[1].Requirements = {}
				task.Functions[1].Activations[1].Methods[1].CooldownInfo = {}
				task.Functions[1].Activations[2].Methods[1].CooldownInfo = {}

				task.AutomaticFunctions[1].Methods[1].Info.SelfDamage = 0

				task.AutomaticFunctions[2].Methods[1].Info.SuccessStunLength = 15
				task.Functions[1].Activations[1].Methods[1].Info.SuccessStunLength = 15
				task.Functions[1].Activations[2].Methods[1].Info.SuccessStunLength = 15

				task.AutomaticFunctions[2].Methods[1].Info.SuccessImmortalLength = 10
				task.Functions[1].Activations[1].Methods[1].Info.SuccessImmortalLength = 10
				task.Functions[1].Activations[2].Methods[1].Info.SuccessImmortalLength = 10
				task.Functions[1].Activations[1].Methods[1].Info.ImmortalLength = 10
				task.Functions[1].Activations[2].Methods[1].Info.ImmortalLength = 10

				task.AutomaticFunctions[2].Methods[1].Info.Damage = 110

				StunBaton.Actions.ADS.Enabled = false

				return true
			end)

			if success then
				Success("Stun Baton", "No Auto-Aim mode! Hold click to spam (30 studs range)", 2)
				return true
			else
				Error("Stun Baton", "Failed to enhance: " .. tostring(result), 3)
				warn("Stun Baton error details:", result)
				return false
			end
		end

		return {
			Execute = function()
				return enhanceStunBaton()
			end,
		}
	end)()

	-- REVIVE GRENADE MODULE
	local ReviveGrenadeModule = (function()
		local function enhanceReviveGrenade()
			local success, result = pcall(function()
				-- Fungsi untuk menyuntikkan efek ke dalam tabel Revive Grenade
				local function applyMods(rg)
					if not rg or not rg.Tasks or not rg.Tasks[1] then
						return
					end

					rg.RequiresOwnedItem = false

					local task = rg.Tasks[1]

					-- MODIFIKASI FUNGSI LEMPARAN (THROW)
					if
						task.Functions
						and task.Functions[1]
						and task.Functions[1].Activations
						and task.Functions[1].Activations[1]
					then
						local activation = task.Functions[1].Activations[1]

						-- BIKIN BISA DITAHAN (HOLD TO SPAM)
						activation.CanHoldDown = true

						if activation.Methods and activation.Methods[1] then
							local method = activation.Methods[1]

							-- INFINITE AMMO (Tidak berkurang saat dilempar)
							method.ItemUseIncrement = { "ReviveGrenade", 999 }

							-- HILANGKAN COOLDOWN BIAR BISA SPAM BRUTAL
							if method.Info then
								method.Info.Cooldown = 0.05 -- Cooldown sangat kecil untuk spam
								method.Info.ThrowVelocity = 150 -- Kecepatan lemparan diperkencang
							end

							-- Hapus batasan animasi yang bikin lemparan nyangkut/jeda
							method.CooldownInfo = {}
							method.Requirements = {}
						end
					end

					-- PERCEPAT ANIMASI EQUIP/UNEQUIP (Biar saat dipegang langsung bisa dilempar)
					if task.AutomaticFunctions then
						for _, auto in ipairs(task.AutomaticFunctions) do
							if auto.Methods and auto.Methods[1] and auto.Methods[1].Info then
								auto.Methods[1].Info.Cooldown = 0
							end
						end
					end
				end

				-- 1. Terapkan ke master file di ReplicatedStorage
				local originalRG = require(game:GetService("ReplicatedStorage").Items.Loadout.ReviveGrenade)
				applyMods(originalRG)

				-- 2. Terapkan ke cache memori (Garbage Collection Bypass)
				for _, obj in pairs(getgc(true)) do
					if type(obj) == "table" and rawget(obj, "HUD") and type(obj.HUD) == "table" then
						if rawget(obj.HUD, "Name") == "Revive Grenade" then
							applyMods(obj)
						end
					end
				end

				return true
			end)

			if success then
				Success("Revive Grenade", "Bisa di-hold, spam lempar, & infinite ammo!", 3)
				return true
			else
				Error("Revive Grenade", "Gagal di-enhance: " .. tostring(result), 3)
				warn("Revive Grenade error details:", result)
				return false
			end
		end

		return {
			Execute = function()
				return enhanceReviveGrenade()
			end,
		}
	end)()

	-- ========================================================================== --
	--                         AUTO JUMP / BHOP SYSTEM                            --
	-- ========================================================================== --

	local AutoJumpModule = (function()
		local function createMobileBtn(name, text, posY, cb)
			local sg = Instance.new("ScreenGui")
			sg.Name = name
			sg.ResetOnSpawn = false
			sg.Enabled = false
			pcall(function()
				sg.Parent = gethui()
			end)
			if not sg.Parent then
				sg.Parent = game:GetService("CoreGui")
			end

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 110, 0, 30)
			btn.Position = UDim2.new(0, 10, 0, posY)
			btn.Font = Enum.Font.Code
			btn.TextSize = 12
			btn.Text = text
			btn.AutoButtonColor = false
			btn.Parent = sg

			local stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = btn

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 4)
			corner.Parent = btn

			local drag, ds, sp
			btn.InputBegan:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					drag = true
					ds = i.Position
					sp = btn.Position
				end
			end)
			btn.InputEnded:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					drag = false
				end
			end)
			game:GetService("UserInputService").InputChanged:Connect(function(i)
				if
					(i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch)
					and drag
				then
					btn.Position = UDim2.new(
						sp.X.Scale,
						sp.X.Offset + (i.Position.X - ds.X),
						sp.Y.Scale,
						sp.Y.Offset + (i.Position.Y - ds.Y)
					)
				end
			end)
			btn.MouseButton1Click:Connect(cb)

			return sg, btn, stroke
		end

		local enabled = false
		local holdEnabled = false
		local autoJumpType = "Bounce"
		local bhopMode = "Acceleration"
		local bhopAccelValue = -0.5
		local jumpCooldown = 0.7
		local rotationEnabled = false
		local rotationSpeed = 100000

		local bhopConnection = nil
		local rotationConnection = nil
		local characterConnection = nil
		local frictionTables = {}

		local Character = nil
		local Humanoid = nil
		local HumanoidRootPart = nil
		local LastJump = 0

		local GROUND_CHECK_OFFSET = 3.5
		local GROUND_CHECK_RAY_LENGTH = 4
		local MAX_SLOPE_ANGLE = 45

		local bhopHoldActive = false

		-- ==================== FLOATING MOBILE BTN ====================
		local mobileGui, mobileBtn, mobileStroke = createMobileBtn("BhopMobileBtn", "Bhop: OFF", 220, function()
			if Toggles and Toggles.BunnyHop then
				Toggles.BunnyHop:SetValue(not Toggles.BunnyHop.Value)
			end
		end)

		local function updateMobileBtn()
			if not mobileBtn then
				return
			end

			local accent = (Options and Options.AccentColor and Options.AccentColor.Value)
				or (Library and typeof(Library.AccentColor) == "Color3" and Library.AccentColor)
				or Color3.fromRGB(115, 215, 85)
			local font = (Options and Options.FontColor and Options.FontColor.Value)
				or (Library and typeof(Library.FontColor) == "Color3" and Library.FontColor)
				or Color3.fromRGB(200, 200, 200)
			local main = (Options and Options.MainColor and Options.MainColor.Value)
				or (Library and typeof(Library.MainColor) == "Color3" and Library.MainColor)
				or Color3.fromRGB(20, 20, 20)
			local outline = (Options and Options.OutlineColor and Options.OutlineColor.Value)
				or (Library and typeof(Library.OutlineColor) == "Color3" and Library.OutlineColor)
				or Color3.fromRGB(45, 45, 45)

			mobileBtn.Text = enabled and "Bhop: ON" or "Bhop: OFF"
			mobileBtn.TextColor3 = enabled and accent or font
			mobileBtn.BackgroundColor3 = main
			mobileStroke.Color = outline
		end

		-- ZERO DELAY SYNC
		game:GetService("RunService").Heartbeat:Connect(function()
			if mobileGui and mobileGui.Parent then
				updateMobileBtn()
			end
		end)

		-- ==================== ROTATION 360° ====================
		local function startRotation()
			if rotationConnection then
				rotationConnection:Disconnect()
				rotationConnection = nil
			end

			if not rotationEnabled or not HumanoidRootPart then
				return
			end

			rotationConnection = RunService.Heartbeat:Connect(function(deltaTime)
				if HumanoidRootPart and HumanoidRootPart.Parent then
					local currentRotation = HumanoidRootPart.Orientation
					local newRotation = Vector3.new(
						currentRotation.X,
						currentRotation.Y + (rotationSpeed * deltaTime),
						currentRotation.Z
					)
					HumanoidRootPart.Orientation = newRotation
				else
					if rotationConnection then
						rotationConnection:Disconnect()
						rotationConnection = nil
					end
				end
			end)
		end

		local function stopRotation()
			if rotationConnection then
				rotationConnection:Disconnect()
				rotationConnection = nil
			end
		end

		-- ==================== GROUND CHECK ====================
		local function IsOnGround()
			if not Character or not HumanoidRootPart or not Humanoid then
				return false
			end

			local state = Humanoid:GetState()
			if
				state == Enum.HumanoidStateType.Jumping
				or state == Enum.HumanoidStateType.Freefall
				or state == Enum.HumanoidStateType.Swimming
			then
				return false
			end

			if Humanoid:GetState() == Enum.HumanoidStateType.Running then
				return true
			end

			local rayOrigin = HumanoidRootPart.Position
			local rayDirection = Vector3.new(0, -GROUND_CHECK_RAY_LENGTH, 0)

			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
			raycastParams.FilterDescendantsInstances = { Character }
			raycastParams.IgnoreWater = true

			local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

			if raycastResult then
				local surfaceNormal = raycastResult.Normal
				local angle = math.deg(math.acos(surfaceNormal:Dot(Vector3.new(0, 1, 0))))

				if angle <= MAX_SLOPE_ANGLE then
					local heightDiff = math.abs(rayOrigin.Y - raycastResult.Position.Y)
					return heightDiff <= GROUND_CHECK_OFFSET
				end
			end

			if HumanoidRootPart.Velocity.Y > -1 and HumanoidRootPart.Velocity.Y < 1 then
				return true
			end

			return false
		end

		-- ==================== FRICTION TABLES ====================
		local function findFrictionTables()
			frictionTables = {}

			for _, obj in pairs(getgc(true)) do
				if type(obj) == "table" and rawget(obj, "Friction") then
					local safeOriginal = obj.Friction
					if safeOriginal < 0 then
						safeOriginal = 5
					end

					table.insert(frictionTables, {
						obj = obj,
						original = safeOriginal,
					})
				end
			end
		end

		local function applyBhopFriction()
			local isActive = enabled or bhopHoldActive

			if isActive and bhopMode == "Acceleration" then
				if #frictionTables == 0 then
					findFrictionTables()
				end

				for _, tableData in ipairs(frictionTables) do
					if tableData.obj and type(tableData.obj) == "table" then
						pcall(function()
							tableData.obj.Friction = bhopAccelValue
						end)
					end
				end
			else
				for _, tableData in ipairs(frictionTables) do
					if tableData.obj and type(tableData.obj) == "table" and tableData.original then
						pcall(function()
							tableData.obj.Friction = tableData.original
						end)
					end
				end
			end
		end

		-- ==================== BHOP UPDATE ====================
		local function updateBhop()
			local isActive = enabled or bhopHoldActive

			if not isActive then
				return
			end

			if not Character or not Humanoid or not HumanoidRootPart then
				Character = player.Character
				if Character then
					Humanoid = Character:FindFirstChildOfClass("Humanoid")
					HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
				end
				if not Humanoid or not HumanoidRootPart then
					return
				end
			end

			if Humanoid:GetState() == Enum.HumanoidStateType.Dead then
				return
			end

			local now = tick()

			if autoJumpType == "Realistic" then
				pcall(function()
					player.PlayerScripts.Events.temporary_events.JumpReact:Fire()
					player.PlayerScripts.Events.temporary_events.EndJump:Fire()
				end)
			else
				if IsOnGround() and (now - LastJump) > 0.25 then
					Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					LastJump = now
				end
			end
		end

		-- ==================== LOAD/UNLOAD ====================
		local function loadBhop()
			applyBhopFriction()
			if bhopConnection then
				bhopConnection:Disconnect()
			end
			bhopConnection = RunService.Heartbeat:Connect(function(deltaTime)
				updateBhop()
			end)
		end

		local function unloadBhop()
			if bhopConnection then
				bhopConnection:Disconnect()
				bhopConnection = nil
			end
			bhopHoldActive = false
			applyBhopFriction()
		end

		local function checkBhopState()
			local shouldLoad = enabled or bhopHoldActive

			if shouldLoad then
				loadBhop()
				if rotationEnabled and enabled then
					startRotation()
				else
					stopRotation()
				end
			else
				unloadBhop()
				stopRotation()
			end
		end

		-- ==================== CHARACTER UPDATES ====================
		RunService.Heartbeat:Connect(function()
			if not Character or not Character:IsDescendantOf(workspace) then
				Character = player.Character
				if Character then
					Humanoid = Character:FindFirstChildOfClass("Humanoid")
					HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
					if rotationEnabled and enabled then
						startRotation()
					end
				else
					Humanoid = nil
					HumanoidRootPart = nil
					stopRotation()
				end
			end
		end)

		characterConnection = player.CharacterAdded:Connect(function(character)
			Character = character
			task.wait(0.5)
			Humanoid = character:WaitForChild("Humanoid")
			HumanoidRootPart = character:WaitForChild("HumanoidRootPart")

			frictionTables = {}

			if enabled or bhopHoldActive then
				task.wait(1)
				checkBhopState()
			end

			if rotationEnabled and enabled then
				startRotation()
			end
		end)

		-- ==================== INPUT HANDLERS ====================
		UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
			if gameProcessedEvent then
				return
			end

			if input.KeyCode == Enum.KeyCode.Space and holdEnabled then
				bhopHoldActive = true
				checkBhopState()
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.Space then
				bhopHoldActive = false
				checkBhopState()
			end
		end)

		-- ==================== PUBLIC FUNCTIONS ====================
		local function start()
			if enabled then
				return
			end
			enabled = true
			checkBhopState()
			Success("Auto Jump", "Activated (" .. autoJumpType .. " mode)", 2)
		end

		local function stop()
			if not enabled then
				return
			end
			enabled = false
			checkBhopState()
			Info("Auto Jump", "Disabled", 2)
		end

		local function toggleRotation(state)
			rotationEnabled = state
			if state and enabled then
				startRotation()
				Success("Rotation 360°", "Activated", 2)
			else
				stopRotation()
				Info("Rotation 360°", "Disabled", 2)
			end
		end

		return {
			Start = start,
			Stop = stop,
			IsEnabled = function()
				return enabled
			end,
			SetMobileVisible = function(state)
				mobileGui.Enabled = state
			end,

			SetAutoJumpType = function(type)
				autoJumpType = type
				Info("Auto Jump", "Type: " .. type, 1)
			end,

			SetBhopMode = function(mode)
				bhopMode = mode
				checkBhopState()
				Info("Bhop Mode", mode, 1)
			end,

			SetBhopAccel = function(accel)
				local num = tonumber(accel)
				if num and num < 0 then
					bhopAccelValue = num
					if enabled or bhopHoldActive then
						applyBhopFriction()
					end
					Success("Bhop Accel", "Set to: " .. num, 1)
				end
			end,

			SetJumpCooldown = function(cooldown)
				local num = tonumber(cooldown)
				if num and num > 0 then
					jumpCooldown = num
					Success("Jump Cooldown", "Set to: " .. num .. "s", 1)
				end
			end,

			ToggleRotation = toggleRotation,
			IsRotationEnabled = function()
				return rotationEnabled
			end,

			SetHoldEnabled = function(state)
				holdEnabled = state
			end,
		}
	end)()

	-- ========================================================================== --
	--                         BOUNCE MODIFICATION MODULE                         --
	-- ========================================================================== --

	local BounceModule = (function()
		local enabled = false
		local bounceSpeed = 110
		local bounceConnection = nil

		local function updateBounce()
			if not enabled then
				return
			end

			local gamePlayers = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
			if not gamePlayers then
				return
			end

			local playerModel = gamePlayers:FindFirstChild(player.Name)
			if not playerModel then
				return
			end

			local humanoid = playerModel:FindFirstChild("Humanoid")
			if not humanoid then
				return
			end

			humanoid.WalkSpeed = bounceSpeed
		end

		local function start()
			if bounceConnection then
				return
			end
			enabled = true

			bounceConnection = RunService.Heartbeat:Connect(updateBounce)

			Success("Bounce Mod", "Activated (Speed: " .. bounceSpeed .. ")", 2)
		end

		local function stop()
			enabled = false

			if bounceConnection then
				bounceConnection:Disconnect()
				bounceConnection = nil
			end

			-- Reset speed
			local gamePlayers = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
			if gamePlayers then
				local playerModel = gamePlayers:FindFirstChild(player.Name)
				if playerModel then
					local humanoid = playerModel:FindFirstChild("Humanoid")
					if humanoid then
						humanoid.WalkSpeed = 0
					end
				end
			end

			Info("Bounce Mod", "Disabled", 2)
		end

		player.CharacterAdded:Connect(function()
			task.wait(1)
			if enabled then
				updateBounce()
			end
		end)

		return {
			Start = start,
			Stop = stop,
			IsEnabled = function()
				return enabled
			end,
			SetSpeed = function(speed)
				local num = tonumber(speed)
				if num and num > 0 and num <= 1000 then
					bounceSpeed = num
					if enabled then
						updateBounce()
						Success("Bounce Speed", "Set to: " .. num, 1)
					end
				end
			end,
		}
	end)()

	-- ========================================================================== --
	--                         GRAVITY SYSTEM MODULE                              --
	-- ========================================================================== --

	local GravityModule = (function()
		local enabled = false
		local originalGravity = workspace.Gravity
		local gravityValue = 10

		local function start()
			if enabled then
				return
			end
			enabled = true

			workspace.Gravity = gravityValue

			Success("Gravity", "Activated (Value: " .. gravityValue .. ")", 2)
		end

		local function stop()
			if not enabled then
				return
			end
			enabled = false

			workspace.Gravity = originalGravity

			Info("Gravity", "Disabled (Reset to: " .. originalGravity .. ")", 2)
		end

		return {
			Start = start,
			Stop = stop,
			IsEnabled = function()
				return enabled
			end,
			SetGravity = function(gravity)
				local num = tonumber(gravity)
				if num and num > 0 then
					gravityValue = num
					if enabled then
						workspace.Gravity = num
						Success("Gravity", "Set to: " .. num, 1)
					end
				end
			end,
			GetOriginalGravity = function()
				return originalGravity
			end,
		}
	end)()

	-- ========================================================================== --
	--                    MANUAL SUPER LAUNCH (PURE PHYSICS)                      --
	-- ========================================================================== --
	local GrappleGlitchModule = (function()
		local function createMobileBtn(name, text, posY, cb)
			local sg = Instance.new("ScreenGui")
			sg.Name = name
			sg.ResetOnSpawn = false
			sg.Enabled = false
			pcall(function()
				sg.Parent = gethui()
			end)
			if not sg.Parent then
				sg.Parent = game:GetService("CoreGui")
			end

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 110, 0, 30)
			btn.Position = UDim2.new(0, 10, 0, posY)
			btn.Font = Enum.Font.Code
			btn.TextSize = 12
			btn.Text = text
			btn.AutoButtonColor = false
			btn.Parent = sg

			local stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = btn

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 4)
			corner.Parent = btn

			local drag, ds, sp
			btn.InputBegan:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					drag = true
					ds = i.Position
					sp = btn.Position
				end
			end)
			btn.InputEnded:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					drag = false
				end
			end)
			game:GetService("UserInputService").InputChanged:Connect(function(i)
				if
					(i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch)
					and drag
				then
					btn.Position = UDim2.new(
						sp.X.Scale,
						sp.X.Offset + (i.Position.X - ds.X),
						sp.Y.Scale,
						sp.Y.Offset + (i.Position.Y - ds.Y)
					)
				end
			end)
			btn.MouseButton1Click:Connect(cb)

			return sg, btn, stroke
		end

		local enabled = false
		local launchHeight = 150
		local launchDistance = 200
		local launchDirection = "Maju"

		local uis = game:GetService("UserInputService")
		local player = game:GetService("Players").LocalPlayer
		local inputBeganConn = nil
		local inputEndedConn = nil

		local isVHeld = false

		local function PerformLaunch()
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")

			if hrp then
				local camera = workspace.CurrentCamera
				local finalVelocity = Vector3.new(0, launchHeight, 0)

				hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

				if launchDirection == "Mouse" then
					local mouse = player:GetMouse()
					if mouse.Hit then
						local dir = (mouse.Hit.Position - hrp.Position).Unit
						finalVelocity = (dir * launchDistance) + Vector3.new(0, launchHeight, 0)
					end
				else
					local camLook = camera.CFrame.LookVector
					local camRight = camera.CFrame.RightVector

					local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
					if flatLook.Magnitude > 0.001 then
						flatLook = flatLook.Unit
					else
						flatLook = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z).Unit
					end

					local flatRight = Vector3.new(camRight.X, 0, camRight.Z)
					if flatRight.Magnitude > 0.001 then
						flatRight = flatRight.Unit
					else
						flatRight = Vector3.new(hrp.CFrame.RightVector.X, 0, hrp.CFrame.RightVector.Z).Unit
					end

					if launchDirection == "Maju" then
						finalVelocity = finalVelocity + (flatLook * launchDistance)
					elseif launchDirection == "Mundur" then
						finalVelocity = finalVelocity + (-flatLook * launchDistance)
					elseif launchDirection == "Kiri" then
						finalVelocity = finalVelocity + (-flatRight * launchDistance)
					elseif launchDirection == "Kanan" then
						finalVelocity = finalVelocity + (flatRight * launchDistance)
					end
				end

				hrp.AssemblyLinearVelocity = finalVelocity
			end
		end

		local mobileGui, mobileBtn, mobileStroke = createMobileBtn("GlitchMobileBtn", "Glitch Launch", 140, function()
			if enabled then
				PerformLaunch()
			else
				if Library and Library.Notify then
					Library:Notify({
						Title = "Super Launch",
						Description = "Nyalakan toggle Grapple Glitch dulu!",
						Time = 2,
					})
				end
			end
		end)

		-- ZERO DELAY SYNC
		game:GetService("RunService").Heartbeat:Connect(function()
			if mobileGui and mobileGui.Parent and mobileBtn then
				local font = (Options and Options.FontColor and Options.FontColor.Value)
					or (Library and typeof(Library.FontColor) == "Color3" and Library.FontColor)
					or Color3.fromRGB(200, 200, 200)
				local main = (Options and Options.MainColor and Options.MainColor.Value)
					or (Library and typeof(Library.MainColor) == "Color3" and Library.MainColor)
					or Color3.fromRGB(20, 20, 20)
				local outline = (Options and Options.OutlineColor and Options.OutlineColor.Value)
					or (Library and typeof(Library.OutlineColor) == "Color3" and Library.OutlineColor)
					or Color3.fromRGB(45, 45, 45)

				mobileBtn.TextColor3 = font
				mobileBtn.BackgroundColor3 = main
				mobileStroke.Color = outline
			end
		end)

		local function start()
			if enabled then
				return
			end
			enabled = true

			inputBeganConn = uis.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then
					return
				end

				if input.KeyCode == Enum.KeyCode.V then
					isVHeld = true
				end

				if input.UserInputType == Enum.UserInputType.MouseButton1 and isVHeld then
					PerformLaunch()
				end
			end)

			inputEndedConn = uis.InputEnded:Connect(function(input, gameProcessed)
				if input.KeyCode == Enum.KeyCode.V then
					isVHeld = false
				end
			end)

			Success("Super Launch", "Mode Pure Physics Aktif! Tanpa Noclip.", 2)
		end

		local function stop()
			enabled = false
			isVHeld = false
			if inputBeganConn then
				inputBeganConn:Disconnect()
				inputBeganConn = nil
			end
			if inputEndedConn then
				inputEndedConn:Disconnect()
				inputEndedConn = nil
			end
			Info("Super Launch", "Dimatikan.", 2)
		end

		return {
			Start = start,
			Stop = stop,
			IsEnabled = function()
				return enabled
			end,
			SetMobileVisible = function(state)
				mobileGui.Enabled = state
			end,
			SetHeight = function(val)
				launchHeight = val
			end,
			SetDistance = function(val)
				launchDistance = val
			end,
			SetDirection = function(val)
				launchDirection = val
			end,
		}
	end)()

	-- ========================================================================== --
	--                         INFINITE SLIDE MODULE                              --
	-- ========================================================================== --

	local InfiniteSlideModule = (function()
		local function createMobileBtn(name, text, posY, cb)
			local sg = Instance.new("ScreenGui")
			sg.Name = name
			sg.ResetOnSpawn = false
			sg.Enabled = false
			pcall(function()
				sg.Parent = gethui()
			end)
			if not sg.Parent then
				sg.Parent = game:GetService("CoreGui")
			end

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 110, 0, 30)
			btn.Position = UDim2.new(0, 10, 0, posY)
			btn.Font = Enum.Font.Code
			btn.TextSize = 12
			btn.Text = text
			btn.AutoButtonColor = false
			btn.Parent = sg

			local stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = btn

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 4)
			corner.Parent = btn

			local drag, ds, sp
			btn.InputBegan:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					drag = true
					ds = i.Position
					sp = btn.Position
				end
			end)
			btn.InputEnded:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					drag = false
				end
			end)
			game:GetService("UserInputService").InputChanged:Connect(function(i)
				if
					(i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch)
					and drag
				then
					btn.Position = UDim2.new(
						sp.X.Scale,
						sp.X.Offset + (i.Position.X - ds.X),
						sp.Y.Scale,
						sp.Y.Offset + (i.Position.Y - ds.Y)
					)
				end
			end)
			btn.MouseButton1Click:Connect(cb)

			return sg, btn, stroke
		end

		local enabled = false
		local slideFrictionValue = -8
		local movementTables = {}
		local slideConnection = nil
		local charConnection = nil

		local isCurrentlySliding = false

		local requiredKeys = {
			"Friction",
			"AirStrafeAcceleration",
			"JumpHeight",
			"RunDeaccel",
			"JumpSpeedMultiplier",
			"JumpCap",
			"SprintCap",
			"WalkSpeedMultiplier",
			"BhopEnabled",
			"Speed",
			"AirAcceleration",
			"RunAccel",
			"SprintAcceleration",
		}

		-- ==================== FLOATING MOBILE BTN ====================
		local mobileGui, mobileBtn, mobileStroke = createMobileBtn("SlideMobileBtn", "Slide: OFF", 260, function()
			if Toggles and Toggles.InfiniteSlide then
				Toggles.InfiniteSlide:SetValue(not Toggles.InfiniteSlide.Value)
			end
		end)

		local function updateMobileBtn()
			if not mobileBtn then
				return
			end

			local accent = (Options and Options.AccentColor and Options.AccentColor.Value)
				or (Library and typeof(Library.AccentColor) == "Color3" and Library.AccentColor)
				or Color3.fromRGB(115, 215, 85)
			local font = (Options and Options.FontColor and Options.FontColor.Value)
				or (Library and typeof(Library.FontColor) == "Color3" and Library.FontColor)
				or Color3.fromRGB(200, 200, 200)
			local main = (Options and Options.MainColor and Options.MainColor.Value)
				or (Library and typeof(Library.MainColor) == "Color3" and Library.MainColor)
				or Color3.fromRGB(20, 20, 20)
			local outline = (Options and Options.OutlineColor and Options.OutlineColor.Value)
				or (Library and typeof(Library.OutlineColor) == "Color3" and Library.OutlineColor)
				or Color3.fromRGB(45, 45, 45)

			mobileBtn.Text = enabled and "Slide: ON" or "Slide: OFF"
			mobileBtn.TextColor3 = enabled and accent or font
			mobileBtn.BackgroundColor3 = main
			mobileStroke.Color = outline
		end

		-- ZERO DELAY SYNC
		game:GetService("RunService").Heartbeat:Connect(function()
			if mobileGui and mobileGui.Parent then
				updateMobileBtn()
			end
		end)

		local function hasRequiredFields(tbl)
			if typeof(tbl) ~= "table" then
				return false
			end
			for _, key in ipairs(requiredKeys) do
				if rawget(tbl, key) == nil then
					return false
				end
			end
			return true
		end

		local function findMovementTables()
			movementTables = {}
			for _, obj in ipairs(getgc(true)) do
				if hasRequiredFields(obj) then
					table.insert(movementTables, obj)
				end
			end
			return #movementTables > 0
		end

		local function setSlideFriction(value)
			local appliedCount = 0
			for _, tbl in ipairs(movementTables) do
				pcall(function()
					tbl.Friction = value
					appliedCount = appliedCount + 1
				end)
			end
			return appliedCount
		end

		local function getPlayerModel()
			local gameFolder = workspace:FindFirstChild("Game")
			if not gameFolder then
				return nil
			end
			local playersFolder = gameFolder:FindFirstChild("Players")
			if not playersFolder then
				return nil
			end
			return playersFolder:FindFirstChild(player.Name)
		end

		local function slideUpdate()
			if not enabled then
				return
			end

			local playerModel = getPlayerModel()
			if not playerModel then
				return
			end

			local state = playerModel:GetAttribute("State")

			if state == "Slide" then
				pcall(function()
					playerModel:SetAttribute("State", "EmotingSlide")
				end)

				if not isCurrentlySliding then
					isCurrentlySliding = true
					setSlideFriction(slideFrictionValue)
				end
			elseif state == "EmotingSlide" then
				if not isCurrentlySliding then
					isCurrentlySliding = true
					setSlideFriction(slideFrictionValue)
				end
			else
				if isCurrentlySliding then
					isCurrentlySliding = false
					setSlideFriction(5)
				end
			end
		end

		local function onCharacterAdded(character)
			if not enabled then
				return
			end

			for i = 1, 5 do
				task.wait(0.5)
				if getPlayerModel() then
					break
				end
			end

			task.wait(0.5)
			findMovementTables()
		end

		local function start()
			if enabled then
				return
			end
			enabled = true
			isCurrentlySliding = false
			findMovementTables()

			if player.Character then
				task.spawn(function()
					onCharacterAdded(player.Character)
				end)
			end

			charConnection = player.CharacterAdded:Connect(onCharacterAdded)
			slideConnection = RunService.Heartbeat:Connect(slideUpdate)

			Success("Infinite Slide", "Activated (Speed: " .. slideFrictionValue .. ")", 2)
		end

		local function stop()
			if not enabled then
				return
			end
			enabled = false

			if slideConnection then
				slideConnection:Disconnect()
				slideConnection = nil
			end

			if charConnection then
				charConnection:Disconnect()
				charConnection = nil
			end

			setSlideFriction(5)
			movementTables = {}
			isCurrentlySliding = false

			Info("Infinite Slide", "Disabled", 2)
		end

		return {
			Start = start,
			Stop = stop,
			IsEnabled = function()
				return enabled
			end,
			SetMobileVisible = function(state)
				mobileGui.Enabled = state
			end,
			SetSlideSpeed = function(speed)
				local num = tonumber(speed)
				if num then
					slideFrictionValue = num
					if enabled and isCurrentlySliding then
						setSlideFriction(num)
					end
					Success("Slide Speed", "Set to: " .. num, 1)
				end
			end,
		}
	end)()

	-- FLY MODULE
	local FlyModule = (function()
		local flying = false
		local bodyVelocity = nil
		local bodyGyro = nil
		local flyLoop = nil
		local characterAddedConnection = nil
		local flySpeed = 50

		local function startFlying()
			local character = player.Character
			if not character then
				Error("Fly System", "No character found!", 2)
				return false
			end

			local humanoid = character:FindFirstChild("Humanoid")
			local rootPart = character:FindFirstChild("HumanoidRootPart")

			if not humanoid or not rootPart then
				Error("Fly System", "Humanoid or RootPart not found!", 2)
				return false
			end

			flying = true

			local success, err = pcall(function()
				bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				bodyVelocity.Velocity = Vector3.new(0, 0, 0)
				bodyVelocity.Parent = rootPart

				bodyGyro = Instance.new("BodyGyro")
				bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
				bodyGyro.CFrame = rootPart.CFrame
				bodyGyro.Parent = rootPart

				humanoid.PlatformStand = true
			end)

			if success then
				Success("Fly System", "Flying activated! (Speed: " .. flySpeed .. ")", 2)
			else
				Error("Fly System", "Failed to start: " .. tostring(err), 2)
				return false
			end

			return true
		end

		local function stopFlying()
			flying = false

			if bodyVelocity then
				pcall(function()
					bodyVelocity:Destroy()
				end)
				bodyVelocity = nil
			end
			if bodyGyro then
				pcall(function()
					bodyGyro:Destroy()
				end)
				bodyGyro = nil
			end

			local character = player.Character
			if character then
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid then
					pcall(function()
						humanoid.PlatformStand = false
					end)
				end
			end

			Info("Fly System", "Flying deactivated", 2)
		end

		local function updateFly()
			if not flying then
				return
			end
			if not bodyVelocity or not bodyGyro then
				return
			end

			local character = player.Character
			if not character then
				return
			end

			local humanoid = character:FindFirstChild("Humanoid")
			local rootPart = character:FindFirstChild("HumanoidRootPart")

			if not humanoid or not rootPart then
				return
			end

			local camera = workspace.CurrentCamera
			if not camera then
				return
			end

			local cameraCFrame = camera.CFrame
			local direction = Vector3.new(0, 0, 0)
			local moveDirection = humanoid.MoveDirection

			if moveDirection.Magnitude > 0 then
				local forwardVector = cameraCFrame.LookVector
				local rightVector = cameraCFrame.RightVector
				local forwardComponent = moveDirection:Dot(forwardVector) * forwardVector
				local rightComponent = moveDirection:Dot(rightVector) * rightVector
				direction = direction + (forwardComponent + rightComponent).Unit * moveDirection.Magnitude
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				direction = direction + Vector3.new(0, 1, 0)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				direction = direction - Vector3.new(0, 1, 0)
			end

			pcall(function()
				if direction.Magnitude > 0 then
					bodyVelocity.Velocity = direction.Unit * (flySpeed * 2)
				else
					bodyVelocity.Velocity = Vector3.new(0, 0, 0)
				end
				bodyGyro.CFrame = cameraCFrame
			end)
		end

		local function toggleFly(state)
			if state then
				if characterAddedConnection then
					pcall(function()
						characterAddedConnection:Disconnect()
					end)
				end

				characterAddedConnection = player.CharacterAdded:Connect(function(newChar)
					task.wait(0.5)
					if flying == false and state then
						startFlying()
					end
				end)

				startFlying()

				if not flyLoop then
					flyLoop = RunService.RenderStepped:Connect(function()
						if state then
							updateFly()
						end
					end)
				end
			else
				stopFlying()

				if flyLoop then
					pcall(function()
						flyLoop:Disconnect()
					end)
					flyLoop = nil
				end

				if characterAddedConnection then
					pcall(function()
						characterAddedConnection:Disconnect()
					end)
					characterAddedConnection = nil
				end
			end
		end

		local function setFlySpeed(speed)
			local num = tonumber(speed)
			if num and num > 0 then
				flySpeed = num
				if flying then
					Success("Fly System", "Speed set to: " .. flySpeed, 1)
				end
				return true
			end
			return false
		end

		player.CharacterRemoving:Connect(function()
			if flying then
				stopFlying()
				if flyLoop then
					pcall(function()
						flyLoop:Disconnect()
					end)
					flyLoop = nil
				end
			end
		end)

		return {
			Toggle = toggleFly,
			SetSpeed = setFlySpeed,
			GetSpeed = function()
				return flySpeed
			end,
			IsFlying = function()
				return flying
			end,
			Stop = function()
				if flying then
					toggleFly(false)
				end
			end,
			OnCharacterAdded = function()
				if flying then
					task.wait(1)
					startFlying()
				end
			end,
		}
	end)()

	-- ========================================================================== --
	--                  OBSIDIAN FLOATING FPS, MS & TIMER MODULE                  --
	-- ========================================================================== --

	local FPSTimerDisplayModule = (function()
		local enabled = false
		local updateConnection = nil
		local DraggableLabel = nil

		local function start()
			if enabled then
				return
			end
			enabled = true

			-- Buat Draggable Label bawaan Obsidian jika belum ada
			if not DraggableLabel then
				DraggableLabel = Library:AddDraggableLabel("rzprivate | 0 fps | 0 ms | 0:00")
			end
			DraggableLabel:SetVisible(true)

			local FrameTimer = tick()
			local FrameCounter = 0
			local FPS = 60
			local stats = game:GetService("Stats")

			-- Mulai Loop Render
			updateConnection = RunService.RenderStepped:Connect(function()
				if not enabled then
					return
				end

				-- Hitung FPS
				FrameCounter = FrameCounter + 1
				if (tick() - FrameTimer) >= 1 then
					FPS = FrameCounter
					FrameTimer = tick()
					FrameCounter = 0
				end

				-- Ambil Ping (ms) dengan pcall agar aman
				local ping = 0
				pcall(function()
					ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
				end)

				-- Ambil Timer Game Evade
				local timerText = "0:00"
				pcall(function()
					local gameStats = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Stats")
					if gameStats then
						local timerValue = gameStats:GetAttribute("Timer")
						if timerValue then
							local mins = math.floor(timerValue / 60)
							local secs = timerValue % 60
							timerText = string.format("%d:%02d", mins, secs)
						end
					end
				end)

				-- Update teks pada Draggable Label Obsidian
				if DraggableLabel and DraggableLabel.SetText then
					DraggableLabel:SetText(("rzprivate | %s fps | %s ms | %s"):format(math.floor(FPS), ping, timerText))
				end
			end)

			Success("Visual", "Floating stats enabled (Drag to move)", 2)
		end

		local function stop()
			enabled = false
			if updateConnection then
				updateConnection:Disconnect()
				updateConnection = nil
			end
			if DraggableLabel then
				DraggableLabel:SetVisible(false)
			end
			Info("Visual", "Floating stats disabled", 2)
		end

		return {
			Start = start,
			Stop = stop,
			IsEnabled = function()
				return enabled
			end,
			Cleanup = function()
				if updateConnection then
					updateConnection:Disconnect()
				end
				if DraggableLabel then
					DraggableLabel:SetVisible(false)
				end
			end,
		}
	end)()

	-- ========================================================================== --
	--                           ARRAYLIST DISPLAY MODULE                         --
	-- ========================================================================== --

	local ArrayListModule = (function()
		local enabled = false
		local screenGui = nil
		local listFrame = nil
		local updateConnection = nil
		local RunService = game:GetService("RunService")
		local CoreGui = game:GetService("CoreGui")

		local function createUI()
			if CoreGui:FindFirstChild("IRUZ_ArrayList") then
				CoreGui.IRUZ_ArrayList:Destroy()
			end

			screenGui = Instance.new("ScreenGui")
			screenGui.Name = "IRUZ_ArrayList"
			screenGui.IgnoreGuiInset = true
			screenGui.DisplayOrder = 1000
			screenGui.Parent = CoreGui

			listFrame = Instance.new("Frame")
			listFrame.Size = UDim2.new(0, 200, 1, 0)
			listFrame.Position = UDim2.new(1, -210, 0, 10) -- Pojok kanan atas
			listFrame.BackgroundTransparency = 1
			listFrame.Parent = screenGui

			local layout = Instance.new("UIListLayout")
			layout.Parent = listFrame
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			layout.Padding = UDim.new(0, 2)
		end

		local function updateList()
			if not enabled or not listFrame then
				return
			end

			local activeFeatures = {}

			-- Deteksi otomatis dari Toggles milik Linoria
			if Toggles then
				for toggleIdx, toggle in pairs(Toggles) do
					-- Jangan masukkan toggle yang sifatnya pengaturan (misal: EnableNotifications, dll)
					if
						toggle.Value
						and toggle.Text
						and toggleIdx ~= "KeybindMenuOpen"
						and toggleIdx ~= "ShowCustomCursor"
						and toggleIdx ~= "EnableNotifications"
						and toggleIdx ~= "ShowArrayList"
					then
						table.insert(activeFeatures, toggle.Text)
					end
				end
			end

			-- Urutkan berdasarkan panjang teks (terpanjang di atas)
			table.sort(activeFeatures, function(a, b)
				return string.len(a) > string.len(b)
			end)

			-- Hapus UI lama
			for _, child in ipairs(listFrame:GetChildren()) do
				if child:IsA("Frame") then
					child:Destroy()
				end
			end

			-- Render UI baru
			for i, featureName in ipairs(activeFeatures) do
				local rowFrame = Instance.new("Frame")
				rowFrame.Size = UDim2.new(0, 200, 0, 18)
				rowFrame.BackgroundTransparency = 1
				rowFrame.LayoutOrder = i
				rowFrame.Parent = listFrame

				local textLabel = Instance.new("TextLabel")
				textLabel.Size = UDim2.new(1, -6, 1, 0)
				textLabel.BackgroundTransparency = 1
				textLabel.Text = string.lower(featureName) -- Dibuat huruf kecil semua seperti contoh gambarmu
				textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				textLabel.Font = Enum.Font.Code
				textLabel.TextSize = 14
				textLabel.TextXAlignment = Enum.TextXAlignment.Right
				textLabel.TextStrokeTransparency = 0.3 -- Tambah outline hitam sedikit agar terbaca
				textLabel.Parent = rowFrame

				local colorLine = Instance.new("Frame")
				colorLine.Size = UDim2.new(0, 2, 1, 0)
				colorLine.Position = UDim2.new(1, -2, 0, 0)
				colorLine.BorderSizePixel = 0

				-- Efek Pelangi Berjalan (Rainbow Animation)
				local hue = (tick() * 0.1 + (i * 0.05)) % 1
				colorLine.BackgroundColor3 = Color3.fromHSV(hue, 0.6, 1)
				colorLine.Parent = rowFrame
			end
		end

		return {
			Start = function()
				if enabled then
					return
				end
				enabled = true
				createUI()
				-- Update setiap frame agar sinkron
				updateConnection = RunService.RenderStepped:Connect(updateList)
			end,
			Stop = function()
				enabled = false
				if updateConnection then
					updateConnection:Disconnect()
				end
				if screenGui then
					screenGui:Destroy()
				end
			end,
			Cleanup = function()
				if updateConnection then
					updateConnection:Disconnect()
				end
				if screenGui then
					screenGui:Destroy()
				end
			end,
		}
	end)()

	-- ========================================================================== --
	--                         VISUAL FEATURES MODULE                             --
	-- ========================================================================== --

	local VisualFeaturesModule = (function()
		local Lighting = game:GetService("Lighting")

		-- Store original values
		local originalValues = {
			FogEnd = Lighting.FogEnd,
			FogStart = Lighting.FogStart,
			FogColor = Lighting.FogColor,
			Brightness = Lighting.Brightness,
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			ColorShift_Bottom = Lighting.ColorShift_Bottom,
			ColorShift_Top = Lighting.ColorShift_Top,
			GlobalShadows = Lighting.GlobalShadows,
			Atmospheres = {},
		}

		-- Backup atmospheres
		for _, v in pairs(Lighting:GetChildren()) do
			if v:IsA("Atmosphere") then
				table.insert(originalValues.Atmospheres, v:Clone())
			end
		end

		-- ==================== FAKE STREAK ====================
		local function setFakeStreak(value)
			local num = tonumber(value)
			if num then
				local success, err = pcall(function()
					player:SetAttribute("Streak", num)
				end)
				if success then
					Success("Fake Streak", "Streak set to: " .. num, 1)
					return true
				else
					Error("Fake Streak", "Failed to set streak", 1)
					return false
				end
			end
			return false
		end

		local function resetStreak()
			local success, err = pcall(function()
				player:SetAttribute("Streak", nil)
			end)
			if success then
				Success("Fake Streak", "Streak has been reset", 1)
			else
				Error("Fake Streak", "Failed to reset streak", 1)
			end
		end

		-- ==================== CAMERA STRETCH ====================
		local cameraStretchConnection = nil
		local stretchHorizontal = 0.80
		local stretchVertical = 0.80
		local stretchEnabled = false

		local function applyCameraStretch()
			local Camera = workspace.CurrentCamera
			if Camera then
				Camera.CFrame = Camera.CFrame
					* CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
			end
		end

		local function setupCameraStretch()
			if cameraStretchConnection then
				pcall(function()
					cameraStretchConnection:Disconnect()
				end)
			end
			cameraStretchConnection = RunService.RenderStepped:Connect(applyCameraStretch)
		end

		local function toggleCameraStretch(state)
			stretchEnabled = state
			if state then
				setupCameraStretch()
				Success("Camera Stretch", "Activated (H: " .. stretchHorizontal .. ", V: " .. stretchVertical .. ")", 2)
			else
				if cameraStretchConnection then
					pcall(function()
						cameraStretchConnection:Disconnect()
					end)
					cameraStretchConnection = nil
				end
				Info("Camera Stretch", "Deactivated", 2)
			end
		end

		local function setStretchHorizontal(value)
			local num = tonumber(value)
			if num and num > 0 then
				stretchHorizontal = num
				if stretchEnabled then
					Success("Stretch H", "Set to: " .. stretchHorizontal, 1)
				end
				return true
			end
			return false
		end

		local function setStretchVertical(value)
			local num = tonumber(value)
			if num and num > 0 then
				stretchVertical = num
				if stretchEnabled then
					Success("Stretch V", "Set to: " .. stretchVertical, 1)
				end
				return true
			end
			return false
		end

		-- ==================== FULL BRIGHT ====================
		local fullBrightEnabled = false
		local fullBrightConnection = nil

		local function applyFullBright()
			pcall(function()
				if Lighting.Brightness ~= 2 then
					Lighting.Brightness = 2
				end
				if Lighting.Ambient ~= Color3.new(1, 1, 1) then
					Lighting.Ambient = Color3.new(1, 1, 1)
				end
				if Lighting.OutdoorAmbient ~= Color3.new(1, 1, 1) then
					Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
				end
				if Lighting.ColorShift_Bottom ~= Color3.new(1, 1, 1) then
					Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
				end
				if Lighting.ColorShift_Top ~= Color3.new(1, 1, 1) then
					Lighting.ColorShift_Top = Color3.new(1, 1, 1)
				end
				Lighting.GlobalShadows = false

				-- Remove atmospheres
				for _, v in pairs(Lighting:GetChildren()) do
					if v:IsA("Atmosphere") then
						v:Destroy()
					end
				end
			end)
		end

		local function restoreLighting()
			pcall(function()
				Lighting.Brightness = originalValues.Brightness
				Lighting.Ambient = originalValues.Ambient
				Lighting.OutdoorAmbient = originalValues.OutdoorAmbient
				Lighting.ColorShift_Bottom = originalValues.ColorShift_Bottom
				Lighting.ColorShift_Top = originalValues.ColorShift_Top
				Lighting.GlobalShadows = originalValues.GlobalShadows

				-- Restore atmospheres
				for _, atmosphere in ipairs(originalValues.Atmospheres) do
					local newAtmosphere = Instance.new("Atmosphere")
					for _, prop in pairs({ "Density", "Offset", "Color", "Decay", "Glare", "Haze" }) do
						if atmosphere[prop] then
							newAtmosphere[prop] = atmosphere[prop]
						end
					end
					newAtmosphere.Parent = Lighting
				end
			end)
		end

		local function toggleFullBright(state)
			fullBrightEnabled = state

			if state then
				applyFullBright()

				-- Keep full bright active via connection
				if fullBrightConnection then
					fullBrightConnection:Disconnect()
				end

				fullBrightConnection = RunService.Heartbeat:Connect(function()
					if fullBrightEnabled then
						applyFullBright()
					end
				end)

				Success("Full Bright", "Activated", 2)
			else
				if fullBrightConnection then
					fullBrightConnection:Disconnect()
					fullBrightConnection = nil
				end

				restoreLighting()
				Info("Full Bright", "Deactivated", 2)
			end
		end

		-- ==================== ANTI LAG 1 (LIGHT) ====================
		local function antiLag1()
			task.spawn(function()
				pcall(function()
					Lighting.GlobalShadows = false
					Lighting.FogEnd = 1e10
					Lighting.Brightness = 1

					local Terrain = workspace:FindFirstChildOfClass("Terrain")
					if Terrain then
						Terrain.WaterWaveSize = 0
						Terrain.WaterWaveSpeed = 0
						Terrain.WaterReflectance = 0
						Terrain.WaterTransparency = 1
					end

					local partsChanged = 0
					for _, obj in ipairs(workspace:GetDescendants()) do
						if obj:IsA("BasePart") then
							obj.Material = Enum.Material.Plastic
							obj.Reflectance = 0
							partsChanged = partsChanged + 1
						elseif obj:IsA("Decal") or obj:IsA("Texture") then
							obj:Destroy()
						elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
							obj:Destroy()
						elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
							obj:Destroy()
						end
					end

					Success("Anti Lag 1", "Light optimization complete! (" .. partsChanged .. " parts)", 3)
				end)
			end)
		end

		-- ==================== ANTI LAG 2 (AGGRESSIVE) ====================
		local function antiLag2()
			task.spawn(function()
				pcall(function()
					local stats = {
						parts = 0,
						particles = 0,
						effects = 0,
						textures = 0,
						sky = 0,
					}

					-- PERBAIKAN: Ubah game:GetDescendants() menjadi workspace:GetDescendants()
					-- Agar tidak merusak UI dan sistem internal game di ReplicatedStorage
					for _, v in next, workspace:GetDescendants() do
						if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("BasePart") then
							v.Material = Enum.Material.SmoothPlastic
							stats.parts = stats.parts + 1
						end

						if
							v:IsA("ParticleEmitter")
							or v:IsA("Smoke")
							or v:IsA("Explosion")
							or v:IsA("Sparkles")
							or v:IsA("Fire")
						then
							v.Enabled = false
							stats.particles = stats.particles + 1
						end

						if v:IsA("Decal") or v:IsA("Texture") then
							v.Texture = ""
							stats.textures = stats.textures + 1
						end
					end

					-- Lighting effects aman ditaruh di sini
					for _, v in next, Lighting:GetChildren() do
						if
							v:IsA("BloomEffect")
							or v:IsA("BlurEffect")
							or v:IsA("DepthOfFieldEffect")
							or v:IsA("SunRaysEffect")
						then
							v.Enabled = false
							stats.effects = stats.effects + 1
						elseif v:IsA("Sky") then
							v.Parent = nil
							stats.sky = stats.sky + 1
						end
					end

					Success("Anti Lag 2", "Aggressive optimization complete!", 3)
				end)
			end)
		end

		-- ==================== ANTI LAG 3 (TEXTURES) ====================
		local function antiLag3()
			task.spawn(function()
				pcall(function()
					local texturesRemoved = 0
					local decalsRemoved = 0

					for _, part in ipairs(workspace:GetDescendants()) do
						if part:IsA("Part") or part:IsA("MeshPart") or part:IsA("UnionOperation") then
							if part:IsA("Part") then
								part.Material = Enum.Material.SmoothPlastic
							end

							local texture = part:FindFirstChildWhichIsA("Texture")
							if texture then
								texture.Texture = "rbxassetid://0"
								texturesRemoved = texturesRemoved + 1
							end

							local decal = part:FindFirstChildWhichIsA("Decal")
							if decal then
								decal.Texture = "rbxassetid://0"
								decalsRemoved = decalsRemoved + 1
							end
						end
					end

					Success(
						"Anti Lag 3",
						"Textures: " .. texturesRemoved .. ", Decals: " .. decalsRemoved .. " cleared",
						3
					)
				end)
			end)
		end

		-- ==================== REMOVE FOG ====================
		local removeFogEnabled = false

		local function applyRemoveFog()
			pcall(function()
				Lighting.FogEnd = 1000000
				for _, v in pairs(Lighting:GetChildren()) do
					if v:IsA("Atmosphere") then
						v:Destroy()
					end
				end
			end)
		end

		local function restoreFog()
			pcall(function()
				Lighting.FogEnd = originalValues.FogEnd
				for _, atmosphere in ipairs(originalValues.Atmospheres) do
					local newAtmosphere = Instance.new("Atmosphere")
					for _, prop in pairs({ "Density", "Offset", "Color", "Decay", "Glare", "Haze" }) do
						if atmosphere[prop] then
							newAtmosphere[prop] = atmosphere[prop]
						end
					end
					newAtmosphere.Parent = Lighting
				end
			end)
		end

		local function toggleRemoveFog(state)
			removeFogEnabled = state

			if state then
				applyRemoveFog()
				Success("Remove Fog", "Activated", 2)
			else
				restoreFog()
				Info("Remove Fog", "Deactivated", 2)
			end
		end

		-- Character respawn handler
		player.CharacterAdded:Connect(function()
			task.wait(1)
			if fullBrightEnabled then
				applyFullBright()
			end
			if removeFogEnabled then
				applyRemoveFog()
			end
		end)

		return {
			SetFakeStreak = setFakeStreak,
			ResetStreak = resetStreak,

			ToggleCameraStretch = toggleCameraStretch,
			SetStretchH = setStretchHorizontal,
			SetStretchV = setStretchVertical,
			IsStretchEnabled = function()
				return stretchEnabled
			end,

			ToggleFullBright = toggleFullBright,
			IsFullBright = function()
				return fullBrightEnabled
			end,

			AntiLag1 = antiLag1,
			AntiLag2 = antiLag2,
			AntiLag3 = antiLag3,

			ToggleRemoveFog = toggleRemoveFog,
			IsRemoveFog = function()
				return removeFogEnabled
			end,
		}
	end)()

	-- ========================================================================== --
	--                         LAG SWITCH MODULE (FIXED)                          --
	-- ========================================================================== --

	local LagSwitchModule = (function()
		local enabled = false
		local lagMode = "Normal"
		local lagDelay = 0.1
		local lagIntensity = 1000000
		local demonHeight = 10
		local demonSpeed = 80
		local isLagActive = false

		-- Fungsi Inti Lag (Math)
		local function performMathLag()
			local startTime = tick()
			while tick() - startTime < lagDelay do
				for i = 1, lagIntensity do
					local a = math.random(1, 1000) * math.random(1, 1000)
				end
			end
		end

		-- Fungsi Demon (Rise)
		local function performDemonLag()
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then
				return
			end

			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
			bodyVelocity.Velocity = Vector3.new(0, demonSpeed, 0)
			bodyVelocity.Parent = hrp

			task.spawn(performMathLag) -- Jalankan lag di background
			task.wait(lagDelay)

			bodyVelocity:Destroy()
			Success("Demon Mode", "Launched to " .. demonHeight .. "m", 1)
		end

		-- FUNGSI UTAMA YANG DIPANGGIL KEYBIND
		local function executeLag()
			if not enabled then
				return
			end -- Harus ON dulu togglenya
			if isLagActive then
				return
			end

			isLagActive = true
			if lagMode == "Normal" then
				task.spawn(function()
					performMathLag()
					isLagActive = false
					Success("Lag Switch", "Lag Burst Done!", 1)
				end)
			else
				task.spawn(function()
					performDemonLag()
					isLagActive = false
				end)
			end
		end

		return {
			Execute = executeLag, -- Fungsi baru untuk trigger
			SetEnabled = function(state)
				enabled = state
			end,
			SetMode = function(mode)
				lagMode = mode
			end,
			SetDelay = function(val)
				lagDelay = tonumber(val) or 0.1
			end,
			SetIntensity = function(val)
				lagIntensity = tonumber(val) or 1000000
			end,
			SetDemonHeight = function(val)
				demonHeight = tonumber(val) or 10
			end,
			SetDemonSpeed = function(val)
				demonSpeed = tonumber(val) or 80
			end,
			IsEnabled = function()
				return enabled
			end,
		}
	end)()

	-- ========================================================================== --
	--                          AUTO BUY SHOP MODULE                              --
	-- ========================================================================== --

	local AutoBuyModule = (function()
		local enabled = false
		local autoBuyItemName = ""
		local buyDelay = 5
		local buyLoop = nil

		-- DATABASE DINAMIS
		local categorizedItems = {} -- Format: { ["Loadout"] = {"Cola", "Sensor"}, ["Emotes"] = {...} }
		local itemIDLookup = {} -- Format: { ["Cola"] = 141, ["Macarena"] = 555 }

		-- ==================== KATEGORI AUTO SCANNER ====================
		local function scanShopItems()
			local RS = game:GetService("ReplicatedStorage")
			local itemsFolder = RS:FindFirstChild("Items")

			if itemsFolder then
				local count = 0
				for _, obj in ipairs(itemsFolder:GetDescendants()) do
					if obj:IsA("ModuleScript") then
						local id = obj:GetAttribute("ID")
						if id then
							local category = obj.Parent and obj.Parent.Name or "Unknown"

							-- Buat tabel kategori jika belum ada
							if not categorizedItems[category] then
								categorizedItems[category] = {}
							end

							-- Simpan nama item ke dalam kategori
							table.insert(categorizedItems[category], obj.Name)

							-- Simpan Lookup ID untuk fungsi pembelian
							itemIDLookup[obj.Name] = id
							count = count + 1
						end
					end
				end

				-- Sortir item di dalam setiap kategori berdasarkan abjad
				for cat, items in pairs(categorizedItems) do
					table.sort(items)
				end
			end
		end

		scanShopItems()
		-- ===============================================================

		-- Mengambil list nama Kategori (Loadout, Emotes, dsb)
		local function getCategories()
			local cats = {}
			for cat, _ in pairs(categorizedItems) do
				table.insert(cats, cat)
			end
			table.sort(cats)
			if #cats == 0 then
				table.insert(cats, "None")
			end
			return cats
		end

		-- Mengambil list item berdasarkan kategori yang dipilih
		local function getItemsByCategory(category)
			if categorizedItems[category] then
				return categorizedItems[category]
			end
			return { "None" }
		end

		-- Fungsi beli manual
		local function purchase(itemName, amount)
			amount = amount or 1
			local itemID = itemIDLookup[itemName]

			if not itemID or itemName == "None" or itemName == "" then
				Error("Shop", "Pilih item yang valid terlebih dahulu!", 3)
				return
			end

			task.spawn(function()
				local bought = 0
				for i = 1, amount do
					local success, result = pcall(function()
						return ReplicatedStorage.Events.Data.Purchase:InvokeServer(itemID)
					end)
					if success and result == true then
						bought = bought + 1
					end
					task.wait(0.2)
				end

				if bought > 0 then
					Success("Shop", "Berhasil membeli " .. bought .. "x " .. itemName .. "!", 2)
				else
					Error("Shop", "Gagal! Uang kurang atau item maksimal.", 3)
				end
			end)
		end

		-- Fungsi Auto Buy (Looping)
		local function startAutoBuy()
			if buyLoop then
				return
			end
			local itemID = itemIDLookup[autoBuyItemName]
			if not itemID then
				return
			end

			enabled = true
			buyLoop = task.spawn(function()
				while enabled do
					pcall(function()
						ReplicatedStorage.Events.Data.Purchase:InvokeServer(itemID)
					end)
					task.wait(buyDelay)
				end
			end)
			Success("Auto Buy", "Otomatis membeli " .. autoBuyItemName .. " setiap " .. buyDelay .. " detik.", 2)
		end

		local function stopAutoBuy()
			enabled = false
			if buyLoop then
				task.cancel(buyLoop)
				buyLoop = nil
			end
			Info("Auto Buy", "Dihentikan.", 2)
		end

		-- Print Scanner Data ke F9
		local function printScannedItems()
			warn("====== HASIL SCAN KATEGORI EVADE ======")
			local total = 0
			for cat, items in pairs(categorizedItems) do
				warn(">> KATEGORI: " .. cat)
				for _, name in ipairs(items) do
					print("   - " .. name .. " (ID: " .. tostring(itemIDLookup[name]) .. ")")
					total = total + 1
				end
			end
			warn("Total: " .. total .. " item")
			warn("=======================================")
			Library:Notify({ Title = "Scanner", Description = "Cek layar console (F9)!", Time = 3 })
		end

		return {
			GetCategories = getCategories,
			GetItems = getItemsByCategory,
			Purchase = purchase,
			Start = startAutoBuy,
			Stop = stopAutoBuy,
			SetItem = function(itemName)
				autoBuyItemName = itemName
			end,
			SetDelay = function(delay)
				buyDelay = delay
			end,
			IsEnabled = function()
				return enabled
			end,
			PrintScannedItems = printScannedItems,
		}
	end)()

	-- UNLOCK LEADERBOARD MODULE
	local UnlockLeaderboardModule = (function()
		local buttonGui = nil
		local player = game:GetService("Players").LocalPlayer
		local TweenService = game:GetService("TweenService")
		local StarterGui = game:GetService("StarterGui")

		local function createLeaderboardUI()
			if buttonGui and buttonGui.Parent then
				pcall(function()
					buttonGui:Destroy()
				end)
			end

			local playerGui = player:WaitForChild("PlayerGui")

			local existing = playerGui:FindFirstChild("CustomTopGui")
			if existing then
				existing:Destroy()
			end

			pcall(function()
				StarterGui:SetCore("TopbarEnabled", false)
			end)

			local screenGui = Instance.new("ScreenGui")
			screenGui.Name = "CustomTopGui"
			screenGui.IgnoreGuiInset = false
			screenGui.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets
			screenGui.DisplayOrder = 100
			screenGui.ResetOnSpawn = false
			screenGui.Parent = playerGui
			buttonGui = screenGui

			local container = Instance.new("Frame")
			container.Name = "ButtonContainer"
			container.Parent = screenGui
			container.BackgroundTransparency = 1
			container.Size = UDim2.new(1, -20, 1, 0)
			container.Position = UDim2.new(0, 10, 0, 10)

			local layout = Instance.new("UIListLayout")
			layout.Parent = container
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			layout.VerticalAlignment = Enum.VerticalAlignment.Top
			layout.Padding = UDim.new(0, 8)

			local buttonsConfig = {
				{
					name = "FrontViewButton",
					icon = "rbxassetid://78648212535999",
					label = "Front View",
					keys = { "Reload", "FrontView", "View" },
					color = Color3.fromRGB(45, 45, 45),
				},
				{
					name = "LeaderboardButton",
					icon = "rbxassetid://5107166345",
					label = "Leaderboard",
					keys = { "Leaderboard", "Scoreboard" },
					color = Color3.fromRGB(45, 45, 45),
				},
			}

			local function triggerKey(key, state)
				pcall(function()
					local useKeybind = player.PlayerScripts.Events.temporary_events.UseKeybind
					if useKeybind then
						useKeybind:Fire({ Key = key, Down = state })
					end
				end)
			end

			for _, config in ipairs(buttonsConfig) do
				local btnFrame = Instance.new("Frame")
				btnFrame.Name = config.name
				btnFrame.Parent = container
				btnFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				btnFrame.BackgroundTransparency = 0.3
				btnFrame.BorderSizePixel = 0
				btnFrame.Size = UDim2.new(0, 44, 0, 44)
				btnFrame.ZIndex = 10

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(1, 0)
				corner.Parent = btnFrame

				local icon = Instance.new("ImageLabel")
				icon.Name = "Icon"
				icon.Parent = btnFrame
				icon.BackgroundTransparency = 1
				icon.Size = UDim2.new(0.7, 0, 0.7, 0)
				icon.Position = UDim2.new(0.15, 0, 0.15, 0)
				icon.Image = config.icon
				icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
				icon.ZIndex = 11

				local clickBtn = Instance.new("TextButton")
				clickBtn.Name = "ClickButton"
				clickBtn.Parent = btnFrame
				clickBtn.BackgroundTransparency = 1
				clickBtn.Size = UDim2.new(1, 0, 1, 0)
				clickBtn.ZIndex = 20
				clickBtn.Text = ""
				clickBtn.AutoButtonColor = false

				local label = Instance.new("TextLabel")
				label.Name = "Label"
				label.Parent = btnFrame
				label.BackgroundTransparency = 1
				label.Position = UDim2.new(0, 0, 1, 5)
				label.Size = UDim2.new(1, 0, 0, 16)
				label.Font = Enum.Font.GothamBold
				label.Text = config.label
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
				label.TextSize = 12
				label.TextStrokeTransparency = 0.5
				label.ZIndex = 12
				label.Visible = false

				clickBtn.MouseEnter:Connect(function()
					btnFrame.BackgroundTransparency = 0
					label.Visible = true
				end)

				clickBtn.MouseLeave:Connect(function()
					btnFrame.BackgroundTransparency = 0.3
					label.Visible = false
				end)

				clickBtn.MouseButton1Down:Connect(function()
					btnFrame.BackgroundTransparency = 0.5
					for _, key in ipairs(config.keys) do
						triggerKey(key, true)
					end
				end)

				clickBtn.MouseButton1Up:Connect(function()
					btnFrame.BackgroundTransparency = 0
					for _, key in ipairs(config.keys) do
						triggerKey(key, false)
					end
				end)

				clickBtn.MouseLeave:Connect(function()
					btnFrame.BackgroundTransparency = 0.3
					label.Visible = false
					for _, key in ipairs(config.keys) do
						triggerKey(key, false)
					end
				end)
			end

			return screenGui
		end

		local function destroyLeaderboardUI()
			if buttonGui and buttonGui.Parent then
				pcall(function()
					buttonGui:Destroy()
				end)
				buttonGui = nil
			end

			pcall(function()
				StarterGui:SetCore("TopbarEnabled", true)
			end)
		end

		return {
			Create = function()
				local success, err = pcall(createLeaderboardUI)
				if success then
					Success("Leaderboard", "Custom UI created!", 2)
					return true
				else
					Error("Leaderboard", "Failed: " .. tostring(err), 3)
					return false
				end
			end,
			Destroy = destroyLeaderboardUI,
			Toggle = function()
				if buttonGui and buttonGui.Parent then
					destroyLeaderboardUI()
					Info("Leaderboard", "Custom UI destroyed", 2)
				else
					createLeaderboardUI()
					Success("Leaderboard", "Custom UI created!", 2)
				end
			end,
		}
	end)()

	-- ========================================================================== --
	--                           NEWS POPUP MODULE                                --
	-- ========================================================================== --

	local NewsPopupModule = (function()
		local CoreGui = game:GetService("CoreGui")
		local TweenService = game:GetService("TweenService")
		local isShowing = false

		local function showPopup(config)
			if isShowing then
				return
			end
			isShowing = true

			-- Konfigurasi Default
			config = config or {}
			local titleText = config.Title or "News!"
			local imageId = config.ImageId or "rbxassetid://7221520721"
			local joinLink = config.JoinLink or "https://t.me/rzprvt"

			-- Bersihkan UI lama jika ada
			if CoreGui:FindFirstChild("IRUZ_NewsPopup") then
				CoreGui.IRUZ_NewsPopup:Destroy()
			end

			-- ================= UI CREATION =================
			local ScreenGui = Instance.new("ScreenGui")
			ScreenGui.Name = "IRUZ_NewsPopup"
			ScreenGui.DisplayOrder = 9999
			ScreenGui.IgnoreGuiInset = true
			ScreenGui.Parent = CoreGui

			local DimBackground = Instance.new("Frame")
			DimBackground.Size = UDim2.new(1, 0, 1, 0)
			DimBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			DimBackground.BackgroundTransparency = 1
			DimBackground.Parent = ScreenGui

			local MainFrame = Instance.new("Frame")
			MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
			MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
			MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			MainFrame.BorderSizePixel = 0
			MainFrame.ClipsDescendants = true
			MainFrame.BackgroundTransparency = 1
			MainFrame.Size = UDim2.new(0, 450, 0, 310) -- Ukuran awal (lebih kecil)
			MainFrame.Parent = ScreenGui

			local UICorner = Instance.new("UICorner")
			UICorner.CornerRadius = UDim.new(0, 6)
			UICorner.Parent = MainFrame

			local UIStroke = Instance.new("UIStroke")
			UIStroke.Color = Color3.fromRGB(45, 45, 45)
			UIStroke.Thickness = 1
			UIStroke.Transparency = 1
			UIStroke.Parent = MainFrame

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Size = UDim2.new(1, 0, 0, 45)
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Text = titleText
			TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
			TitleLabel.Font = Enum.Font.Code
			TitleLabel.TextSize = 18
			TitleLabel.TextTransparency = 1
			TitleLabel.Parent = MainFrame

			local ImageBox = Instance.new("ImageLabel")
			ImageBox.Size = UDim2.new(1, -40, 1, -110)
			ImageBox.Position = UDim2.new(0, 20, 0, 45)
			ImageBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
			ImageBox.Image = imageId
			ImageBox.ScaleType = Enum.ScaleType.Crop
			ImageBox.ImageTransparency = 1
			ImageBox.Parent = MainFrame

			local ImageCorner = Instance.new("UICorner")
			ImageCorner.CornerRadius = UDim.new(0, 4)
			ImageCorner.Parent = ImageBox

			local ButtonContainer = Instance.new("Frame")
			ButtonContainer.Size = UDim2.new(1, -40, 0, 35)
			ButtonContainer.Position = UDim2.new(0, 20, 1, -50)
			ButtonContainer.BackgroundTransparency = 1
			ButtonContainer.Parent = MainFrame

			local ButtonLayout = Instance.new("UIListLayout")
			ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
			ButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			ButtonLayout.Padding = UDim.new(0, 15)
			ButtonLayout.Parent = ButtonContainer

			local BtnJoin = Instance.new("TextButton")
			BtnJoin.Size = UDim2.new(0.5, -7, 1, 0)
			BtnJoin.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			BtnJoin.Text = "Join Community"
			BtnJoin.TextColor3 = Color3.fromRGB(200, 200, 200)
			BtnJoin.Font = Enum.Font.Code
			BtnJoin.TextSize = 14
			BtnJoin.AutoButtonColor = false
			BtnJoin.BackgroundTransparency = 1
			BtnJoin.TextTransparency = 1
			BtnJoin.Parent = ButtonContainer

			local BtnJoinCorner = Instance.new("UICorner")
			BtnJoinCorner.CornerRadius = UDim.new(0, 4)
			BtnJoinCorner.Parent = BtnJoin

			local BtnJoinStroke = Instance.new("UIStroke")
			BtnJoinStroke.Color = Color3.fromRGB(45, 45, 45)
			BtnJoinStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			BtnJoinStroke.Transparency = 1
			BtnJoinStroke.Parent = BtnJoin

			local BtnSkip = Instance.new("TextButton")
			BtnSkip.Size = UDim2.new(0.5, -7, 1, 0)
			BtnSkip.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			BtnSkip.Text = "Skip"
			BtnSkip.TextColor3 = Color3.fromRGB(200, 200, 200)
			BtnSkip.Font = Enum.Font.Code
			BtnSkip.TextSize = 14
			BtnSkip.AutoButtonColor = false
			BtnSkip.BackgroundTransparency = 1
			BtnSkip.TextTransparency = 1
			BtnSkip.Parent = ButtonContainer

			local BtnSkipCorner = Instance.new("UICorner")
			BtnSkipCorner.CornerRadius = UDim.new(0, 4)
			BtnSkipCorner.Parent = BtnSkip

			local BtnSkipStroke = Instance.new("UIStroke")
			BtnSkipStroke.Color = Color3.fromRGB(45, 45, 45)
			BtnSkipStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			BtnSkipStroke.Transparency = 1
			BtnSkipStroke.Parent = BtnSkip

			-- ================= HOVER EFFECTS =================
			local function addHoverEffect(button, stroke)
				button.MouseEnter:Connect(function()
					if isShowing then
						button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
						stroke.Color = Color3.fromRGB(80, 80, 80)
					end
				end)
				button.MouseLeave:Connect(function()
					if isShowing then
						button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
						stroke.Color = Color3.fromRGB(45, 45, 45)
					end
				end)
			end
			addHoverEffect(BtnJoin, BtnJoinStroke)
			addHoverEffect(BtnSkip, BtnSkipStroke)

			-- ================= ANIMATION LOGIC =================
			local function closePopup()
				local duration = 0.5
				local info = TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

				TweenService:Create(DimBackground, info, { BackgroundTransparency = 1 }):Play()
				TweenService:Create(MainFrame, info, {
					Size = UDim2.new(0, 430, 0, 300),
					BackgroundTransparency = 1,
				}):Play()

				TweenService:Create(UIStroke, info, { Transparency = 1 }):Play()
				TweenService:Create(TitleLabel, info, { TextTransparency = 1 }):Play()
				TweenService:Create(ImageBox, info, { ImageTransparency = 1 }):Play()
				TweenService:Create(BtnJoin, info, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
				TweenService:Create(BtnSkip, info, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
				TweenService:Create(BtnJoinStroke, info, { Transparency = 1 }):Play()
				TweenService:Create(BtnSkipStroke, info, { Transparency = 1 }):Play()

				task.wait(duration)
				ScreenGui:Destroy()
				isShowing = false
			end

			local function openPopup()
				local duration = 0.8
				local info = TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

				TweenService:Create(DimBackground, info, { BackgroundTransparency = 0.5 }):Play()
				TweenService:Create(MainFrame, info, {
					Size = UDim2.new(0, 480, 0, 340),
					BackgroundTransparency = 0,
				}):Play()

				TweenService:Create(UIStroke, info, { Transparency = 0 }):Play()
				TweenService:Create(TitleLabel, info, { TextTransparency = 0 }):Play()
				TweenService:Create(ImageBox, info, { ImageTransparency = 0 }):Play()
				TweenService:Create(BtnJoin, info, { BackgroundTransparency = 0, TextTransparency = 0 }):Play()
				TweenService:Create(BtnSkip, info, { BackgroundTransparency = 0, TextTransparency = 0 }):Play()
				TweenService:Create(BtnJoinStroke, info, { Transparency = 0 }):Play()
				TweenService:Create(BtnSkipStroke, info, { Transparency = 0 }):Play()
			end

			-- ================= CONNECTIONS =================
			BtnSkip.MouseButton1Click:Connect(closePopup)

			BtnJoin.MouseButton1Click:Connect(function()
				BtnJoin.Text = "Link Copied!"
				pcall(function()
					setclipboard(joinLink)
				end)

				-- Memunculkan notifikasi Linoria di sebelah kanan
				Library:Notify({
					Title = "Link Disalin!",
					Description = "Link komunitas berhasil disalin ke clipboard.",
					Time = 3,
				})

				task.wait(0.8)
				closePopup()
			end)

			-- Mulai animasi buka
			task.delay(0.2, openPopup)
		end

		return {
			Show = showPopup,
			IsShowing = function()
				return isShowing
			end,
		}
	end)()

	-- ESP SYSTEM MODULE
	local ESP_System = {}
	local ESP_Players = game:GetService("Players")
	local ESP_RunService = game:GetService("RunService")
	local ESP_ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ESP_LocalPlayer = ESP_Players.LocalPlayer

	ESP_System.PlayersESP = {}
	ESP_System.TicketsESP = {}
	ESP_System.NextbotsESP = {}
	ESP_System.NextbotNames = {}
	ESP_System.Connections = {}
	ESP_System.Running = false
	ESP_System.ChamsPlayers = {}
	ESP_System.TracerDrawings = {}
	ESP_System.TracerAllDrawings = {}

	ESP_System.Settings = {
		Players = {
			Enabled = false,
			Color = Color3.fromRGB(255, 255, 255),
		},
		Tickets = {
			Enabled = false,
			Color = Color3.fromRGB(255, 165, 0),
		},
		Nextbots = {
			Enabled = false,
			Color = Color3.fromRGB(255, 0, 0),
		},
		ChamsPlayers = {
			Enabled = false,
			FillColor = Color3.fromRGB(255, 0, 0),
			OutlineColor = Color3.fromRGB(255, 255, 255),
			FillTransparency = 0.5,
			OutlineTransparency = 0,
		},
		TracerDowned = {
			Enabled = false,
			Color = Color3.fromRGB(255, 50, 50),
			Thickness = 2,
		},
		TracerAll = {
			Enabled = false,
			ColorNormal = Color3.fromRGB(255, 255, 255),
			ColorDowned = Color3.fromRGB(255, 50, 50),
			Thickness = 2,
		},
	}

	function ESP_System:GetNextbotNames()
		if ESP_ReplicatedStorage:FindFirstChild("NPCs") then
			for _, npc in ipairs(ESP_ReplicatedStorage.NPCs:GetChildren()) do
				table.insert(self.NextbotNames, npc.Name)
			end
		end
		return self.NextbotNames
	end

	function ESP_System:IsNextbot(model)
		if not model or not model.Name then
			return false
		end
		for _, name in ipairs(self.NextbotNames) do
			if model.Name == name then
				return true
			end
		end
		local lowerName = model.Name:lower()
		if
			lowerName:find("nextbot")
			or lowerName:find("scp%-")
			or lowerName:find("^monster")
			or lowerName:find("^creep")
			or lowerName:find("^enemy")
		then
			return true
		end
		if ESP_Players:FindFirstChild(model.Name) then
			return false
		end
		if model:GetAttribute("IsNPC") or model:GetAttribute("Nextbot") then
			return true
		end
		return false
	end

	function ESP_System:GetDistanceFromPlayer(position)
		if not ESP_LocalPlayer.Character or not ESP_LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			return 0
		end
		return (position - ESP_LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
	end

	function ESP_System:CreatePlayerESP(player)
		if not self.Settings.Players.Enabled or player == ESP_LocalPlayer then
			return
		end
		local character = player.Character
		if not character then
			return
		end
		local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
		if not head then
			return
		end
		if self.PlayersESP[player] and self.PlayersESP[player].Parent then
			self.PlayersESP[player]:Destroy()
		end
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "IRUZPlayerESP"
		billboard.Adornee = head
		billboard.Size = UDim2.new(0, 120, 0, 40)
		billboard.StudsOffset = Vector3.new(0, 3.5, 0)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = 1500
		billboard.Active = true
		billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		billboard.Parent = head
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = player.Name
		textLabel.TextColor3 = self.Settings.Players.Color
		textLabel.TextSize = 14
		textLabel.Font = Enum.Font.RobotoMono
		textLabel.TextStrokeTransparency = 0.5
		textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		textLabel.Parent = billboard
		self.PlayersESP[player] = billboard
		return billboard
	end

	function ESP_System:UpdatePlayersESP()
		if not self.Settings.Players.Enabled then
			self:ClearPlayersESP()
			return
		end
		for player, esp in pairs(self.PlayersESP) do
			if player and player.Character and esp and esp.Parent then
				local character = player.Character
				local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
				local textLabel = esp:FindFirstChildOfClass("TextLabel")
				if
					head
					and textLabel
					and ESP_LocalPlayer.Character
					and ESP_LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				then
					local distance = self:GetDistanceFromPlayer(head.Position)
					local textColor = self.Settings.Players.Color
					local extraText = ""
					if character:FindFirstChild("Revives") then
						textColor = Color3.fromRGB(255, 255, 0)
						extraText = "] [Revives"
					elseif safeIsPlayerDowned(player) then -- ✅ DIGANTI PAKAI safeIsPlayerDowned
						textColor = Color3.fromRGB(255, 0, 0)
						extraText = "] [Downed"
					end
					textLabel.Text = string.format("%s [%dm%s]", player.Name, math.floor(distance), extraText)
					textLabel.TextColor3 = textColor
				end
			else
				if esp then
					pcall(function()
						esp:Destroy()
					end)
				end
				self.PlayersESP[player] = nil
			end
		end
		for _, player in ipairs(ESP_Players:GetPlayers()) do
			if player ~= ESP_LocalPlayer and not self.PlayersESP[player] and player.Character then
				self:CreatePlayerESP(player)
			end
		end
	end

	function ESP_System:ClearPlayersESP()
		for _, esp in pairs(self.PlayersESP) do
			pcall(function()
				esp:Destroy()
			end)
		end
		self.PlayersESP = {}
	end

	function ESP_System:UpdateTicketsESP()
		if not self.Settings.Tickets.Enabled then
			self:ClearTicketsESP()
			return
		end
		local ticketsFound = {}
		local gameFolder = workspace:FindFirstChild("Game")
		if gameFolder then
			local effects = gameFolder:FindFirstChild("Effects")
			if effects then
				local tickets = effects:FindFirstChild("Tickets")
				if tickets then
					for _, ticket in pairs(tickets:GetChildren()) do
						if ticket:IsA("BasePart") or ticket:IsA("Model") then
							local part = ticket:IsA("Model")
									and (ticket:FindFirstChild("HumanoidRootPart") or ticket:FindFirstChild("Head") or ticket.PrimaryPart or ticket:FindFirstChildWhichIsA(
										"BasePart"
									))
								or ticket:IsA("BasePart") and ticket
							if part then
								ticketsFound[ticket] = part
							end
						end
					end
				end
			end
		end
		for ticket, esp in pairs(self.TicketsESP) do
			if not ticketsFound[ticket] or not ticket.Parent then
				pcall(function()
					esp:Destroy()
				end)
				self.TicketsESP[ticket] = nil
			end
		end
		for ticket, part in pairs(ticketsFound) do
			if not self.TicketsESP[ticket] then
				local billboard = Instance.new("BillboardGui")
				billboard.Name = "IRUZTicketESP"
				billboard.Adornee = part
				billboard.Size = UDim2.new(0, 100, 0, 30)
				billboard.StudsOffset = Vector3.new(0, 2, 0)
				billboard.AlwaysOnTop = true
				billboard.MaxDistance = 1000
				billboard.Parent = part
				local textLabel = Instance.new("TextLabel")
				textLabel.Size = UDim2.new(1, 0, 1, 0)
				textLabel.BackgroundTransparency = 1
				textLabel.TextColor3 = self.Settings.Tickets.Color
				textLabel.TextSize = 12
				textLabel.Font = Enum.Font.RobotoMono
				textLabel.Parent = billboard
				local stroke = Instance.new("UIStroke")
				stroke.Color = Color3.new(0, 0, 0)
				stroke.Thickness = 0.5
				stroke.Parent = textLabel
				self.TicketsESP[ticket] = billboard
			end
			local esp = self.TicketsESP[ticket]
			if esp and esp.Parent and esp:FindFirstChildOfClass("TextLabel") then
				local textLabel = esp:FindFirstChildOfClass("TextLabel")
				local distance = self:GetDistanceFromPlayer(part.Position)
				textLabel.Text = string.format("Ticket [%d m]", math.floor(distance))
			end
		end
	end

	function ESP_System:ClearTicketsESP()
		for _, esp in pairs(self.TicketsESP) do
			pcall(function()
				esp:Destroy()
			end)
		end
		self.TicketsESP = {}
	end

	function ESP_System:CreateFakePartForModel(model)
		if not model or not model:IsA("Model") then
			return nil
		end
		local fakePart = Instance.new("Part")
		fakePart.Name = "IRUZESP_Anchor"
		fakePart.Size = Vector3.new(0.1, 0.1, 0.1)
		fakePart.Transparency = 1
		fakePart.CanCollide = false
		fakePart.Anchored = true
		fakePart.Parent = model
		if model.PrimaryPart then
			fakePart.CFrame = model.PrimaryPart.CFrame
		else
			local success, center = pcall(function()
				return model:GetBoundingBox()
			end)
			if success and center then
				fakePart.CFrame = center
			else
				local firstPart = model:FindFirstChildWhichIsA("BasePart")
				if firstPart then
					fakePart.CFrame = firstPart.CFrame
				end
			end
		end
		return fakePart
	end

	function ESP_System:CreateNextbotESP(model, part)
		if not part then
			return nil
		end
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "IRUZNextbotESP"
		billboard.Parent = part
		billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		billboard.AlwaysOnTop = true
		billboard.LightInfluence = 1
		billboard.Size = UDim2.new(0, 200, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.MaxDistance = 1000
		local textLabel = Instance.new("TextLabel")
		textLabel.Parent = billboard
		textLabel.BackgroundTransparency = 1
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.TextScaled = false
		textLabel.Font = Enum.Font.RobotoMono
		textLabel.TextStrokeTransparency = 0.5
		textLabel.TextSize = 16
		textLabel.TextColor3 = self.Settings.Nextbots.Color
		return billboard
	end

	function ESP_System:UpdateNextbotESP(model, part)
		if not part then
			return false
		end
		local esp = part:FindFirstChild("IRUZNextbotESP")
		if esp and esp:FindFirstChildOfClass("TextLabel") then
			local label = esp:FindFirstChildOfClass("TextLabel")
			local distance = self:GetDistanceFromPlayer(part.Position)
			label.Text = string.format("%s [%d m]", model.Name, math.floor(distance))
			return true
		end
		return false
	end

	function ESP_System:ScanNextbots()
		if not self.Settings.Nextbots.Enabled then
			self:ClearNextbotsESP()
			return
		end
		local nextbots = {}
		local playersFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
		if playersFolder then
			for _, model in ipairs(playersFolder:GetChildren()) do
				if model:IsA("Model") and self:IsNextbot(model) then
					nextbots[model] = model
				end
			end
		end
		local npcsFolder = workspace:FindFirstChild("NPCs")
		if npcsFolder then
			for _, model in ipairs(npcsFolder:GetChildren()) do
				if model:IsA("Model") and self:IsNextbot(model) then
					nextbots[model] = model
				end
			end
		end
		for model in pairs(nextbots) do
			if not self.NextbotsESP[model] then
				local fakePart = model:FindFirstChild("IRUZESP_Anchor") or self:CreateFakePartForModel(model)
				if fakePart then
					local esp = self:CreateNextbotESP(model, fakePart)
					if esp then
						self:UpdateNextbotESP(model, fakePart)
						self.NextbotsESP[model] = { esp = esp, part = fakePart, lastUpdate = tick() }
					end
				end
			else
				local data = self.NextbotsESP[model]
				if data.part and data.part.Parent == model then
					if model.PrimaryPart then
						data.part.CFrame = model.PrimaryPart.CFrame
					else
						local success, center = pcall(function()
							return model:GetBoundingBox()
						end)
						if success and center then
							data.part.CFrame = center
						end
					end
					self:UpdateNextbotESP(model, data.part)
					data.lastUpdate = tick()
				else
					local fakePart = self:CreateFakePartForModel(model)
					if fakePart then
						data.part = fakePart
						local esp = self:CreateNextbotESP(model, fakePart)
						if esp then
							self:UpdateNextbotESP(model, fakePart)
							data.esp = esp
							data.lastUpdate = tick()
						end
					end
				end
			end
		end
		for model, data in pairs(self.NextbotsESP) do
			if not nextbots[model] or not model.Parent then
				pcall(function()
					if data.esp then
						data.esp:Destroy()
					end
					if data.part and data.part.Name == "IRUZESP_Anchor" then
						data.part:Destroy()
					end
				end)
				self.NextbotsESP[model] = nil
			end
		end
	end

	function ESP_System:ClearNextbotsESP()
		for _, data in pairs(self.NextbotsESP) do
			pcall(function()
				if data.esp then
					data.esp:Destroy()
				end
				if data.part and data.part.Name == "IRUZESP_Anchor" then
					data.part:Destroy()
				end
			end)
		end
		self.NextbotsESP = {}
	end

	function ESP_System:CreatePlayerChams(player)
		if not self.Settings.ChamsPlayers.Enabled or player == ESP_LocalPlayer then
			return
		end
		local character = player.Character
		if not character then
			return
		end

		if self.ChamsPlayers[player] then
			pcall(function()
				self.ChamsPlayers[player]:Destroy()
			end)
		end

		local highlight = Instance.new("Highlight")
		highlight.Name = "IRUZPlayerChams"
		highlight.FillColor = self.Settings.ChamsPlayers.FillColor
		highlight.OutlineColor = self.Settings.ChamsPlayers.OutlineColor
		highlight.FillTransparency = self.Settings.ChamsPlayers.FillTransparency
		highlight.OutlineTransparency = self.Settings.ChamsPlayers.OutlineTransparency
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = character

		self.ChamsPlayers[player] = highlight
		return highlight
	end

	function ESP_System:UpdatePlayerChams()
		if not self.Settings.ChamsPlayers.Enabled then
			self:ClearPlayerChams()
			return
		end

		for player, highlight in pairs(self.ChamsPlayers) do
			if not player or not player.Character or not highlight.Parent then
				pcall(function()
					if highlight then
						highlight:Destroy()
					end
				end)
				self.ChamsPlayers[player] = nil
			else
				if safeIsPlayerDowned(player) then -- ✅ DIGANTI PAKAI safeIsPlayerDowned
					highlight.FillColor = Color3.fromRGB(255, 0, 0)
					highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
				else
					highlight.FillColor = self.Settings.ChamsPlayers.FillColor
					highlight.OutlineColor = self.Settings.ChamsPlayers.OutlineColor
				end
			end
		end

		for _, player in ipairs(ESP_Players:GetPlayers()) do
			if player ~= ESP_LocalPlayer and not self.ChamsPlayers[player] and player.Character then
				self:CreatePlayerChams(player)
			end
		end
	end

	function ESP_System:ClearPlayerChams()
		for _, highlight in pairs(self.ChamsPlayers) do
			pcall(function()
				highlight:Destroy()
			end)
		end
		self.ChamsPlayers = {}
	end

	function ESP_System:UpdateTracerDowned()
		if not self.Settings.TracerDowned.Enabled then
			self:ClearTracerDowned()
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		if not ESP_LocalPlayer.Character then
			return
		end

		local screenSize = camera.ViewportSize
		local startPos = Vector2.new(screenSize.X / 2, screenSize.Y)

		local activePlayers = {}

		for _, player in ipairs(ESP_Players:GetPlayers()) do
			if player ~= ESP_LocalPlayer and player.Character then
				-- ✅ GUNAKAN SAFE CHECK
				if safeIsPlayerDowned(player) then
					-- ✅ GUNAKAN SAFE GET POSITION
					local targetPos = safeGetDownedPosition(player)
					if targetPos then
						activePlayers[player] = targetPos
					end
				end
			end
		end

		-- Hapus tracer untuk player yang tidak downed lagi
		for player, line in pairs(self.TracerDrawings) do
			if not activePlayers[player] then
				pcall(function()
					line:Remove()
				end)
				self.TracerDrawings[player] = nil
			end
		end

		-- Update/buat tracer untuk player yang downed
		for player, targetPos in pairs(activePlayers) do
			local success, screenPos, onScreen = pcall(function()
				return camera:WorldToViewportPoint(targetPos)
			end)

			if success and onScreen then
				if not self.TracerDrawings[player] then
					local line = Drawing.new("Line")
					line.Visible = true
					line.Color = self.Settings.TracerDowned.Color
					line.Thickness = self.Settings.TracerDowned.Thickness
					line.Transparency = 1
					self.TracerDrawings[player] = line
				end

				local line = self.TracerDrawings[player]
				line.From = startPos
				line.To = Vector2.new(screenPos.X, screenPos.Y)
				line.Color = self.Settings.TracerDowned.Color
				line.Thickness = self.Settings.TracerDowned.Thickness
				line.Visible = true
			else
				if self.TracerDrawings[player] then
					self.TracerDrawings[player].Visible = false
				end
			end
		end
	end

	function ESP_System:ClearTracerDowned()
		for _, line in pairs(self.TracerDrawings) do
			pcall(function()
				line:Remove()
			end)
		end
		self.TracerDrawings = {}
	end

	function ESP_System:UpdateTracerAll()
		if not self.Settings.TracerAll.Enabled then
			self:ClearTracerAll()
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		if not ESP_LocalPlayer.Character then
			return
		end

		local screenSize = camera.ViewportSize
		local startPos = Vector2.new(screenSize.X / 2, screenSize.Y)

		local activePlayers = {}

		for _, player in ipairs(ESP_Players:GetPlayers()) do
			if player ~= ESP_LocalPlayer and player.Character then
				-- ✅ GUNAKAN SAFE GET POSITION
				local targetPos = safeGetDownedPosition(player)
				if targetPos then
					activePlayers[player] = {
						position = targetPos,
						downed = safeIsPlayerDowned(player), -- ✅ SAFE CHECK
					}
				end
			end
		end

		-- Hapus tracer untuk player yang hilang
		for player, line in pairs(self.TracerAllDrawings) do
			if not activePlayers[player] then
				pcall(function()
					line:Remove()
				end)
				self.TracerAllDrawings[player] = nil
			end
		end

		-- Update/buat tracer
		for player, data in pairs(activePlayers) do
			local success, screenPos, onScreen = pcall(function()
				return camera:WorldToViewportPoint(data.position)
			end)

			if success and onScreen then
				if not self.TracerAllDrawings[player] then
					local line = Drawing.new("Line")
					line.Visible = true
					line.Thickness = self.Settings.TracerAll.Thickness
					line.Transparency = 1
					self.TracerAllDrawings[player] = line
				end

				local line = self.TracerAllDrawings[player]
				line.From = startPos
				line.To = Vector2.new(screenPos.X, screenPos.Y)
				line.Thickness = self.Settings.TracerAll.Thickness
				line.Visible = true

				-- Warna berbeda untuk downed
				if data.downed then
					line.Color = self.Settings.TracerAll.ColorDowned
				else
					line.Color = self.Settings.TracerAll.ColorNormal
				end
			else
				if self.TracerAllDrawings[player] then
					self.TracerAllDrawings[player].Visible = false
				end
			end
		end
	end

	function ESP_System:ClearTracerAll()
		for _, line in pairs(self.TracerAllDrawings) do
			pcall(function()
				line:Remove()
			end)
		end
		self.TracerAllDrawings = {}
	end

	function ESP_System:Start()
		if self.Running then
			return
		end
		self.Running = true
		self:GetNextbotNames()
		for _, p in ipairs(ESP_Players:GetPlayers()) do
			if p ~= ESP_LocalPlayer then
				if p.Character then
					self:CreatePlayerESP(p)
				end
				p.CharacterAdded:Connect(function()
					task.wait(0.5)
					if self.Settings.Players.Enabled then
						self:CreatePlayerESP(p)
					end
				end)
			end
		end
		self.Connections.PlayerAdded = ESP_Players.PlayerAdded:Connect(function(p)
			if p ~= ESP_LocalPlayer then
				p.CharacterAdded:Connect(function()
					task.wait(0.5)
					if self.Settings.Players.Enabled then
						self:CreatePlayerESP(p)
					end
				end)
			end
		end)
		self.Connections.PlayerRemoving = ESP_Players.PlayerRemoving:Connect(function(p)
			if self.PlayersESP[p] then
				pcall(function()
					self.PlayersESP[p]:Destroy()
				end)
				self.PlayersESP[p] = nil
			end
		end)
		self.Connections.CharacterAdded = ESP_LocalPlayer.CharacterAdded:Connect(function()
			task.wait(1)
			if self.Running then
				self:ClearPlayersESP()
				self:ClearNextbotsESP()
				for _, p in ipairs(ESP_Players:GetPlayers()) do
					if p ~= ESP_LocalPlayer and p.Character then
						self:CreatePlayerESP(p)
					end
				end
			end
		end)
		self.Connections.Main = ESP_RunService.Heartbeat:Connect(function()
			if not self.Running then
				return
			end
			pcall(function()
				self:UpdatePlayersESP()
				self:UpdateTicketsESP()
				self:ScanNextbots()
				self:UpdatePlayerChams()
				self:UpdateTracerDowned()
				self:UpdateTracerAll()
			end)
		end)
	end

	function ESP_System:Stop()
		self.Running = false

		-- Putus SEMUA koneksi yang tersimpan dengan aman
		for key, connection in pairs(self.Connections) do
			if connection then
				pcall(function()
					connection:Disconnect()
				end)
			end
		end
		self.Connections = {} -- Reset tabel koneksi agar bersih total

		self:ClearPlayersESP()
		self:ClearTicketsESP()
		self:ClearNextbotsESP()
		self:ClearPlayerChams()
		self:ClearTracerDowned()
		self:ClearTracerAll()
	end

	-- ========================================================================== --
	--                        OOB CLIP MACRO MODULE                               --
	-- ========================================================================== --
	local GrappleClipModule = (function()
		local function createMobileBtn(name, text, posY, cb)
			local sg = Instance.new("ScreenGui")
			sg.Name = name
			sg.ResetOnSpawn = false
			sg.Enabled = false
			pcall(function()
				sg.Parent = gethui()
			end)
			if not sg.Parent then
				sg.Parent = game:GetService("CoreGui")
			end

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 110, 0, 30)
			btn.Position = UDim2.new(0, 10, 0, posY)
			btn.Font = Enum.Font.Code
			btn.TextSize = 12
			btn.Text = text
			btn.AutoButtonColor = false
			btn.Parent = sg

			local stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = btn

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 4)
			corner.Parent = btn

			local drag, ds, sp
			btn.InputBegan:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					drag = true
					ds = i.Position
					sp = btn.Position
				end
			end)
			btn.InputEnded:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					drag = false
				end
			end)
			game:GetService("UserInputService").InputChanged:Connect(function(i)
				if
					(i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch)
					and drag
				then
					btn.Position = UDim2.new(
						sp.X.Scale,
						sp.X.Offset + (i.Position.X - ds.X),
						sp.Y.Scale,
						sp.Y.Offset + (i.Position.Y - ds.Y)
					)
				end
			end)
			btn.MouseButton1Click:Connect(cb)

			return sg, btn, stroke
		end

		local enabled = false
		local selectedSlot = 1
		local macroDelay = 0.05
		local cframeBoost = 3
		local vim = game:GetService("VirtualInputManager")
		local isExecuting = false

		local function executeMacro()
			if not enabled or isExecuting then
				return
			end
			isExecuting = true

			task.spawn(function()
				local char = game:GetService("Players").LocalPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")

				vim:SendKeyEvent(true, Enum.KeyCode.G, false, game)
				vim:SendKeyEvent(false, Enum.KeyCode.G, false, game)
				task.wait()

				local keys = {
					Enum.KeyCode.One,
					Enum.KeyCode.Two,
					Enum.KeyCode.Three,
					Enum.KeyCode.Four,
					Enum.KeyCode.Five,
					Enum.KeyCode.Six,
				}
				local targetKey = keys[selectedSlot]

				if targetKey then
					vim:SendKeyEvent(true, targetKey, false, game)
					vim:SendKeyEvent(false, targetKey, false, game)
				end

				task.wait(macroDelay)

				if hrp and cframeBoost > 0 then
					hrp.CFrame = hrp.CFrame + (hrp.CFrame.LookVector * cframeBoost)
				end

				vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
				task.wait(0.05)
				vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)

				task.wait(0.1)
				isExecuting = false
			end)
		end

		local mobileGui, mobileBtn, mobileStroke = createMobileBtn("ClipMobileBtn", "GrappleEmote", 180, function()
			if enabled then
				executeMacro()
			else
				if Library and Library.Notify then
					Library:Notify({
						Title = "GrappleEmote",
						Description = "Nyalakan toggle GrappleEmote dulu!",
						Time = 2,
					})
				end
			end
		end)

		-- ZERO DELAY SYNC
		game:GetService("RunService").Heartbeat:Connect(function()
			if mobileGui and mobileGui.Parent and mobileBtn then
				local font = (Options and Options.FontColor and Options.FontColor.Value)
					or (Library and typeof(Library.FontColor) == "Color3" and Library.FontColor)
					or Color3.fromRGB(200, 200, 200)
				local main = (Options and Options.MainColor and Options.MainColor.Value)
					or (Library and typeof(Library.MainColor) == "Color3" and Library.MainColor)
					or Color3.fromRGB(20, 20, 20)
				local outline = (Options and Options.OutlineColor and Options.OutlineColor.Value)
					or (Library and typeof(Library.OutlineColor) == "Color3" and Library.OutlineColor)
					or Color3.fromRGB(45, 45, 45)

				mobileBtn.TextColor3 = font
				mobileBtn.BackgroundColor3 = main
				mobileStroke.Color = outline
			end
		end)

		return {
			SetEnabled = function(state)
				enabled = state
			end,
			SetMobileVisible = function(state)
				mobileGui.Enabled = state
			end,
			SetSlot = function(val)
				local num = string.match(val, "%d+")
				selectedSlot = tonumber(num) or 1
			end,
			SetDelay = function(val)
				macroDelay = tonumber(val) or 0.05
			end,
			SetCFrameBoost = function(val)
				cframeBoost = tonumber(val) or 3
			end,
			Execute = executeMacro,
		}
	end)()

	-- ========================================================================== --
	--                            CHARACTER CONNECTIONS                            --
	-- ========================================================================== --

	_G.MainCharacterConnection = player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then
			return
		end
		task.wait(0.5)
		NoclipModule.OnCharacterAdded()
		BugEmoteModule.OnCharacterAdded()
		RemoveBarriersModule.OnCharacterAdded()
		BarriersVisibleModule.OnCharacterAdded()
		FlyModule.OnCharacterAdded()
	end)

	-- ========================================================================== --
	--                          EMOTE CHANGER MODULE                              --
	-- ========================================================================== --

	local EmoteChangerModule = (function()
		local player = game:GetService("Players").LocalPlayer
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Events = ReplicatedStorage:WaitForChild("Events", 10)
		local CharacterFolder = Events and Events:WaitForChild("Character", 10)
		local EmoteRemote = CharacterFolder and CharacterFolder:WaitForChild("Emote", 10)
		local PassCharacterInfo = CharacterFolder and CharacterFolder:WaitForChild("PassCharacterInfo", 10)

		local remoteSignal = PassCharacterInfo and PassCharacterInfo.OnClientEvent
		local currentTag = nil

		local currentEmotes = table.create(5, "")
		local selectEmotes = table.create(5, "None")
		local emoteEnabled = table.create(5, false)

		local function readTagFromFolder(f)
			if not f then
				return nil
			end
			local a = f:GetAttribute("Tag")
			if a ~= nil then
				return a
			end
			local o = f:FindFirstChild("Tag")
			if o and o:IsA("ValueBase") then
				return o.Value
			end
			return nil
		end

		local function onRespawn()
			currentTag = nil
			getgenv().pendingSlot = nil

			task.spawn(function()
				local startTime = tick()
				while tick() - startTime < 10 do
					if workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players") then
						local pf = workspace.Game.Players:FindFirstChild(player.Name)
						if pf then
							currentTag = readTagFromFolder(pf)
							if currentTag then
								local b = tonumber(currentTag)
								if b and b >= 0 and b <= 255 then
									break
								else
									currentTag = nil
								end
							end
						end
					end
					task.wait(0.5)
				end
			end)
		end

		getgenv().pendingSlot = nil
		getgenv().blockOriginalEmote = false

		local function fireSelect(slot)
			if not currentTag then
				return
			end

			local b = tonumber(currentTag)
			if not b or b < 0 or b > 255 then
				return
			end
			if not selectEmotes[slot] or selectEmotes[slot] == "" or selectEmotes[slot] == "None" then
				return
			end

			local buf = buffer.create(2)
			buffer.writeu8(buf, 0, b)
			buffer.writeu8(buf, 1, 17)

			if remoteSignal then
				pcall(function()
					firesignal(remoteSignal, buf, { selectEmotes[slot] })
				end)
			end
		end

		local isHooked = false

		local function init()
			if isHooked then
				return
			end
			if not (PassCharacterInfo and EmoteRemote) then
				return
			end

			PassCharacterInfo.OnClientEvent:Connect(function(...)
				if not getgenv().pendingSlot then
					return
				end
				local slot = getgenv().pendingSlot
				getgenv().pendingSlot = nil
				task.wait(0.1)
				fireSelect(slot)
			end)

			local oldNamecall
			local success = pcall(function()
				oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
					local m = getnamecallmethod()
					local a = { ... }

					if m == "FireServer" and self == EmoteRemote and type(a[1]) == "string" then
						for i = 1, 5 do
							if emoteEnabled[i] and currentEmotes[i] ~= "" and a[1] == currentEmotes[i] then
								getgenv().pendingSlot = i
								getgenv().blockOriginalEmote = true

								task.spawn(function()
									task.wait(0.1)
									getgenv().blockOriginalEmote = false
									if getgenv().pendingSlot == i then
										getgenv().pendingSlot = nil
										fireSelect(i)
									end
								end)

								if getgenv().blockOriginalEmote then
									return nil
								end
							end
						end
					end
					return oldNamecall(self, ...)
				end)
			end)

			if success then
				isHooked = true

				if player.Character then
					task.spawn(onRespawn)
				end

				player.CharacterAdded:Connect(function()
					task.wait(1)
					onRespawn()
				end)

				if workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players") then
					workspace.Game.Players.ChildAdded:Connect(function(child)
						if child.Name == player.Name then
							task.wait(0.5)
							onRespawn()
						end
					end)
					workspace.Game.Players.ChildRemoved:Connect(function(child)
						if child.Name == player.Name then
							currentTag = nil
							getgenv().pendingSlot = nil
						end
					end)
				end
			end
		end

		local function normalizeEmoteName(name)
			return name:gsub("%s+", ""):lower()
		end

		local function isValidEmote(emoteName)
			if emoteName == "" or emoteName == "None" then
				return false, ""
			end

			local normalizedInput = normalizeEmoteName(emoteName)
			local emotesFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Items")
			if emotesFolder then
				emotesFolder = emotesFolder:FindFirstChild("Emotes")
				if emotesFolder then
					for _, emoteModule in ipairs(emotesFolder:GetChildren()) do
						if emoteModule:IsA("ModuleScript") then
							if normalizeEmoteName(emoteModule.Name) == normalizedInput then
								return true, emoteModule.Name
							end
						end
					end
				end
			end
			return false, ""
		end

		local function applyMappings()
			local hasAnyEmote = false
			for i = 1, 5 do
				if currentEmotes[i] ~= "" or (selectEmotes[i] ~= "" and selectEmotes[i] ~= "None") then
					hasAnyEmote = true
					break
				end
			end

			if not hasAnyEmote then
				return false, "Silakan isi emote terlebih dahulu!"
			end

			local successfulSlots = 0
			local msg = ""

			for i = 1, 5 do
				if currentEmotes[i] ~= "" and selectEmotes[i] ~= "" and selectEmotes[i] ~= "None" then
					local currentValid, currentActual = isValidEmote(currentEmotes[i])
					local selectValid, selectActual = isValidEmote(selectEmotes[i])

					if not currentValid and not selectValid then
						emoteEnabled[i] = false
						msg = msg .. "Slot " .. i .. ": Emote awal & baru tidak valid.\n"
					elseif not currentValid then
						emoteEnabled[i] = false
						msg = msg .. "Slot " .. i .. ": Emote awal tidak valid.\n"
					elseif not selectValid then
						emoteEnabled[i] = false
						msg = msg .. "Slot " .. i .. ": Emote baru tidak valid.\n"
					elseif currentActual:lower() == selectActual:lower() then
						emoteEnabled[i] = false
						msg = msg .. "Slot " .. i .. ": Emote tidak boleh sama.\n"
					else
						currentEmotes[i] = currentActual
						selectEmotes[i] = selectActual
						emoteEnabled[i] = true
						successfulSlots = successfulSlots + 1
					end
				else
					emoteEnabled[i] = false
				end
			end

			if successfulSlots > 0 then
				return true, "Berhasil memanipulasi " .. successfulSlots .. " emote!\n" .. msg
			else
				return false, "Gagal:\n" .. msg
			end
		end

		return {
			Init = init,
			SetCurrent = function(slot, val)
				currentEmotes[slot] = val:gsub("%s+", "")
			end,
			SetSelect = function(slot, val)
				selectEmotes[slot] = val:gsub("%s+", "")
			end,
			Apply = applyMappings,
			Reset = function()
				for i = 1, 5 do
					currentEmotes[i] = ""
					selectEmotes[i] = "None"
					emoteEnabled[i] = false
				end
			end,
		}
	end)()

	-- ========================================================================== --
	--                        OBSIDIAN LOADING SCREEN                             --
	-- ========================================================================== --

	local Loading = Library:CreateLoading({
		Title = "rzprivate",
		Icon = "rbxassetid://0",
		TotalSteps = 4,
	})

	-- Memulai Loading Sequence
	Loading:SetMessage("Initializing...")
	Loading:SetDescription("Waiting for game to load...")
	task.wait(1)

	Loading:SetCurrentStep(1)
	Loading:SetDescription("Patching anticheat & loading modules...")
	task.wait(1)

	-- Menampilkan Sidebar dengan Info Player & Script
	Loading:SetCurrentStep(2)
	Loading:ShowSidebarPage(true)
	Loading.Sidebar:AddLabel("User: " .. player.Name)
	Loading.Sidebar:AddLabel("Game: Evade")
	Loading.Sidebar:AddLabel("Version: v3.1 (Obsidian)")

	local executorName = "Unknown"
	pcall(function()
		executorName = identifyexecutor() or "Unknown"
	end)
	Loading.Sidebar:AddLabel("Executor: " .. executorName)

	Loading:SetDescription("Building User Interface...")
	task.wait(1.5)

	Loading:SetCurrentStep(3)
	Loading:SetDescription("Ready to start!")
	task.wait(0.5)

	Loading:SetCurrentStep(4)
	Loading:Continue() -- Menutup loader dan melanjutkan ke UI utama

	NewsPopupModule.Show({
		Title = "Welcome to rzprivate v3.1!",
		ImageId = "rbxassetid://7221520721", -- Ganti ID Gambar di sini
		JoinLink = "https://t.me/rzprvt", -- Link tujuan saat tombol diklik
	})

	-- ========================================================================== --
	--                             CREATE WINDOW                                  --
	-- ========================================================================== --

	-- Pastikan Window Main Hub Anda dikembalikan ke AutoShow = true
	local Window = Library:CreateWindow({
		Title = "rzprivate",
		Footer = "t.me/rzprvt | version 3.1",
		NotifySide = "Right",
		ShowCustomCursor = true,
		AutoShow = false,
	})

	local Tabs = {
		Info = Window:AddTab("Info", "info"),
		Combat = Window:AddTab("Combat", "swords"),
		Teleport = Window:AddTab("Teleport", "navigation"),
		ESP = Window:AddTab("ESP", "scan-eye"),
		Movement = Window:AddTab("Movement", "activity"),
		Visual = Window:AddTab("Visual", "eye"),
		Emotes = Window:AddTab("Emotes", "smile"),
		AutoFarm = Window:AddTab("Auto Farm", "zap"),
		AutoBuy = Window:AddTab("Shop", "shopping-cart"),
		PlayerSettings = Window:AddTab("Player Settings", "user"),
		Server = Window:AddTab("Server", "server"),
		["UI Settings"] = Window:AddTab("UI Settings", "settings"),
	}

	-- ========================================================================== --
	--                           INFO TAB (REMASTERED)                            --
	-- ========================================================================== --

	-- Menggunakan Groupbox agar info langsung terlihat rapi
	local ScriptInfoGroup = Tabs.Info:AddLeftGroupbox("Script Info")

	local CommunityGroup = Tabs.Info:AddRightGroupbox("Community & Support")
	local SystemGroup = Tabs.Info:AddRightGroupbox("System Info")

	-- ==================== KIRI: SCRIPT INFO ====================
	ScriptInfoGroup:AddLabel("Name: <font color='#FFFFFF'><b>rzprivate - Evade</b></font>")
	ScriptInfoGroup:AddLabel("Version: <font color='#73D755'><b>3.1 (Obsidian)</b></font>")
	ScriptInfoGroup:AddLabel("Author: <font color='#55A1FF'><b>iruz</b></font>")
	ScriptInfoGroup:AddLabel("Last Update: <font color='#AAAAAA'>April 2026</font>")

	ScriptInfoGroup:AddDivider()

	ScriptInfoGroup:AddLabel("UI Library: <font color='#FF5555'>Linoria (Obsidian)</font>")
	ScriptInfoGroup:AddLabel("Lib Author: <font color='#AAAAAA'>deividcomsono</font>")

	ScriptInfoGroup:AddDivider()

	ScriptInfoGroup:AddLabel("<font color='#73D755'><b>Status: All systems operational</b></font>")

	ScriptInfoGroup:AddDivider()

	-- ==================== CUSTOM PROFILE CARD INJECTION (LEFT SIDE) ====================
	-- Ukuran diperbesar dan diperlebar agar teks lebih terlihat jelas
	local profileContainer = Instance.new("Frame")
	profileContainer.Name = "CustomProfileCard"
	profileContainer.BackgroundTransparency = 1
	profileContainer.Size = UDim2.new(1, 0, 0, 55) -- Tinggi dinaikkan ke 55
	profileContainer.Parent = ScriptInfoGroup.Container

	-- 1. Foto Profil Avatar (Ukuran diperbesar)
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, 42, 0, 42) -- Ukuran jadi 42x42
	avatar.Position = UDim2.new(0, 5, 0.5, -21)
	avatar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	avatar.ZIndex = 5
	avatar.Parent = profileContainer

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatar

	task.spawn(function()
		local success, content = pcall(function()
			return game:GetService("Players")
				:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)
		if success then
			avatar.Image = content
		end
	end)

	-- 2. Nama User (Digeser lebih ke kanan dan diperlebar)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -60, 0, 20) -- Area teks lebih luas
	nameLabel.Position = UDim2.new(0, 55, 0, 6) -- Digeser ke kanan agar tidak menabrak foto
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.Name
	nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	nameLabel.TextSize = 15 -- Font diperbesar dikit
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 5
	nameLabel.Parent = profileContainer

	-- ==================== LOGIKA STATUS PREMIUM / FREEMIUM ====================
	local isPremium = _G.IsPremium or false
	local tagTextString = isPremium and "PREMIUM" or "FREEMIUM"
	local tagColor = isPremium and (Library.AccentColor or Color3.fromRGB(115, 215, 85)) or Color3.fromRGB(85, 170, 255)

	-- 3. Background Tag (Disesuaikan posisinya dengan nama baru)
	local tagFrame = Instance.new("Frame")
	tagFrame.Size = UDim2.new(0, isPremium and 55 or 65, 0, 16) -- Box tag lebih lebar
	tagFrame.Position = UDim2.new(0, 55, 0, 28) -- Sejajar di bawah nama
	tagFrame.BackgroundColor3 = tagColor
	tagFrame.BorderSizePixel = 0
	tagFrame.ZIndex = 5
	tagFrame.Parent = profileContainer

	local tagCorner = Instance.new("UICorner")
	tagCorner.CornerRadius = UDim.new(0, 4)
	tagCorner.Parent = tagFrame

	-- 4. Teks Tag
	local tagText = Instance.new("TextLabel")
	tagText.Size = UDim2.new(1, 0, 1, 0)
	tagText.BackgroundTransparency = 1
	tagText.Text = tagTextString
	tagText.TextColor3 = Color3.fromRGB(15, 15, 15)
	tagText.TextSize = 10 -- Teks tag lebih terbaca
	tagText.Font = Enum.Font.GothamBold
	tagText.ZIndex = 6
	tagText.Parent = tagFrame

	-- ==================== KANAN: COMMUNITY ====================
	CommunityGroup:AddLabel("<font color='#FFFFFF'><b>Join our community for updates!</b></font>")

	CommunityGroup:AddInput("Telegram", {
		Default = "t.me/rzprvt",
		Numeric = false,
		Finished = true,
		Text = "Telegram Link",
		Tooltip = "Join our Telegram for updates & support!",
		Placeholder = "t.me/rzprvt",
	})

	CommunityGroup:AddButton({
		Text = "Copy Telegram Link",
		Tooltip = "Copy Telegram invite to clipboard",
		Func = function()
			local telegramLink = Options.Telegram.Value or "t.me/rzprvt"
			local success = pcall(function()
				setclipboard(telegramLink)
			end)

			if success then
				Library:Notify({ Title = "Telegram", Description = "Link copied to clipboard!", Time = 2 })
			else
				Library:Notify({
					Title = "Telegram",
					Description = "Clipboard not supported by your executor",
					Time = 2,
				})
			end
		end,
	})

	-- ==================== KANAN: SYSTEM INFO ====================
	local executorName = "Unknown"
	pcall(function()
		executorName = identifyexecutor() or "Unknown"
	end)

	SystemGroup:AddLabel("Game: <font color='#FFFFFF'><b>Evade</b></font>")
	SystemGroup:AddLabel("Executor: <font color='#FFB055'><b>" .. executorName .. "</b></font>")

	SystemGroup:AddDivider()

	SystemGroup:AddLabel("<font color='#55A1FF'><b>Need Help?</b></font>")
	SystemGroup:AddLabel("• Join Telegram for support")
	SystemGroup:AddLabel("• Check UI Settings tab")
	SystemGroup:AddLabel("• Read tooltips (hover buttons)")

	SystemGroup:AddDivider()

	-- ========================================================================== --
	--                            COMBAT TAB                                      --
	-- ========================================================================== --

	local CombatLeftBox = Tabs.Combat:AddLeftTabbox()
	local CombatRightBox = Tabs.Combat:AddRightTabbox()

	local AntiBotGroup = CombatLeftBox:AddTab("Anti-Bot")
	local CombatLeft = CombatLeftBox:AddTab("Auto Revive")
	local CombatRight = CombatRightBox:AddTab("Weapons")

	-- 1. TOGGLE UTAMA
	AntiBotGroup:AddToggle("AntiNextbotEnable", {
		Text = "Enable Anti-Nextbot",
		Default = false,
		Tooltip = "Otomatis menghindar jika bot mendekat (Jeda saat Auto Farm)",
	}):AddKeyPicker("AntiBotKey", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Anti-Bot" })

	-- 2. JARAK DETEKSI (Kapan script harus mulai menghindar)
	AntiBotGroup:AddSlider("AntiBotRange", {
		Text = "Detection Range",
		Default = 40,
		Min = 20,
		Max = 100,
		Rounding = 0,
		Callback = function(Value)
			AntiNextbotModule.SetRange(Value)
		end,
	})

	-- 3. METODE EVASI (FITUR BARU)
	AntiBotGroup:AddDropdown("AntiBotType", {
		Values = { "Distance", "Players", "Spawn" },
		Default = "Distance",
		Text = "Evade Method",
		Tooltip = "Distance: Mundur | Players: TP ke teman | Spawn: TP ke Spawn",
		Callback = function(Value)
			AntiNextbotModule.SetType(Value)
		end,
	})

	-- 4. JARAK MUNDUR (FITUR BARU - Hanya berlaku jika metode 'Distance' dipilih)
	AntiBotGroup:AddSlider("AntiBotEvadeDist", {
		Text = "Evade Distance",
		Default = 30,
		Min = 10,
		Max = 100,
		Rounding = 0,
		Callback = function(Value)
			AntiNextbotModule.SetEvadeDistance(Value)
		end,
	})

	-- LOGIKA TOGGLE
	Toggles.AntiNextbotEnable:OnChanged(function()
		if Toggles.AntiNextbotEnable.Value then
			AntiNextbotModule.Start()
		else
			AntiNextbotModule.Stop()
		end
	end)

	-- AUTO REVIVE SECTION
	CombatLeft:AddButton({
		Text = "Revive Yourself (Manual)",
		Tooltip = "Revive yourself manually when downed",
		Func = function()
			local char = player.Character
			if char then
				local isDowned = pcall(function()
					return char:GetAttribute("Downed")
				end)
				if isDowned then
					pcall(function()
						ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
					end)
					Success("Revive Yourself", "Revive attempt sent!", 2)
				else
					Warning("Revive Yourself", "You are not downed!", 2)
				end
			end
		end,
	})

	CombatLeft:AddLabel("Manual Revive Keybind"):AddKeyPicker("ManualReviveKey", {
		Default = "",
		Text = "Manual Revive Keybind",
		Mode = "Press",
		Callback = function()
			local char = player.Character
			if char then
				local isDowned = char:GetAttribute("Downed")
				if isDowned then
					pcall(function()
						ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
					end)
					Success("Revive Yourself", "Revive attempt sent!", 2)
				else
					Warning("Revive Yourself", "You are not downed!", 2)
				end
			end
		end,
	})

	CombatLeft:AddDivider()

	CombatLeft:AddDropdown("SelfReviveMethod", {
		Values = { "Spawnpoint", "Fake Revive" },
		Default = "Spawnpoint",
		Text = "Self Revive Method",
		Tooltip = "Choose auto self revive method",
		Callback = function(Value)
			AutoSelfReviveModule.SetMethod(Value)
		end,
	})

	CombatLeft:AddToggle("AutoSelfRevive", {
		Text = "Auto Self Revive",
		Tooltip = "Automatically revive yourself when downed",
		Default = false,
	}):AddKeyPicker(
		"AutoSelfReviveKey",
		{ Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Auto Self Revive" }
	)

	Toggles.AutoSelfRevive:OnChanged(function()
		if Toggles.AutoSelfRevive.Value then
			AutoSelfReviveModule.Start()
		else
			AutoSelfReviveModule.Stop()
		end
	end)

	CombatLeft:AddDivider()

	-- INSTANT REVIVE TOGGLE
	CombatLeft:AddToggle("InstantRevive", {
		Text = "Instant Revive",
		Tooltip = "Automatically revive downed players in range",
		Default = false,
	}):AddKeyPicker(
		"InstantReviveKey",
		{ Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Instant Revive" }
	)

	Toggles.InstantRevive:OnChanged(function()
		if Toggles.InstantRevive.Value then
			InstantReviveModule.Start()
		else
			InstantReviveModule.Stop()
		end
	end)

	-- REVIVE WHILE EMOTING
	CombatLeft:AddToggle("ReviveWhileEmoting", {
		Text = "Revive While Emoting",
		Tooltip = "Continue reviving even when emoting",
		Default = false,
	})

	Toggles.ReviveWhileEmoting:OnChanged(function()
		InstantReviveModule.SetReviveWhileEmoting(Toggles.ReviveWhileEmoting.Value)
	end)

	-- REVIVE DELAY
	CombatLeft:AddInput("ReviveDelay", {
		Default = "0.15",
		Numeric = true,
		Text = "Revive Delay (seconds)",
		Tooltip = "Lower = faster revive, but may cause lag",
		Placeholder = "0.15",
		Callback = function(Value)
			local num = tonumber(Value)
			if num and num > 0 and num <= 1 then
				InstantReviveModule.SetDelay(num)
			else
				Error("Revive Delay", "Value must be between 0.01 and 1", 2)
			end
		end,
	})

	-- REVIVE RANGE
	CombatLeft:AddInput("ReviveRange", {
		Default = "10",
		Numeric = true,
		Text = "Revive Range (studs)",
		Tooltip = "Distance to auto-revive players",
		Placeholder = "10",
		Callback = function(Value)
			local num = tonumber(Value)
			if num and num > 0 and num <= 100 then
				InstantReviveModule.SetRange(num)
			else
				Error("Revive Range", "Value must be between 1 and 100", 2)
			end
		end,
	})

	-- AUTO WHISTLE SECTION
	CombatLeft:AddDivider()

	CombatLeft:AddToggle("AutoWhistle", {
		Text = "Auto Whistle",
		Tooltip = "Automatically whistle every 1 second",
		Default = false,
	}):AddKeyPicker("AutoWhistleKey", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Auto Whistle" })

	Toggles.AutoWhistle:OnChanged(function()
		if Toggles.AutoWhistle.Value then
			AutoWhistleModule.Start()
		else
			AutoWhistleModule.Stop()
		end
	end)

	CombatLeft:AddInput("AutoWhistleDelay", {
		Default = "1",
		Numeric = true,
		Text = "Whistle Delay (seconds)",
		Tooltip = "Set delay between whistles",
		Placeholder = "Enter seconds",
		Callback = function(Value)
			local num = tonumber(Value)
			if num and num > 0 then
				AutoWhistleModule.SetDelay(num)
			end
		end,
	})

	-- WEAPON ENHANCEMENTS SECTION
	CombatRight:AddButton({
		Text = "Grapplehook",
		Tooltip = "Enhance Grapplehook (200 ammo, no coldown)",
		Func = function()
			GrapplehookModule.Execute()
		end,
	})

	CombatRight:AddButton({
		Text = "Breacher",
		Tooltip = "Enhance Breacher (infinite range, no cooldown)",
		Func = function()
			BreacherModule.Execute()
		end,
	})

	CombatRight:AddButton({
		Text = "Stun Baton",
		Tooltip = "Enhance Stun Baton (no cooldown, super stun)",
		Func = function()
			StunBatonModule.Execute()
		end,
	})

	CombatRight:AddButton({
		Text = "Smoke Grenade",
		Tooltip = "Enhance Smoke Grenade (bigger cloud, faster)",
		Func = function()
			SmokeGrenadeModule.Execute()
		end,
	})

	CombatRight:AddButton({
		Text = "ReviveGranade (ingame Only)",
		Tooltip = "ReviveGranade (spam throw, instant equip)",
		Func = function()
			ReviveGrenadeModule.Execute()
		end,
	})

	CombatRight:AddDivider()

	CombatRight:AddLabel("Status: All weapons ready to enhance", true)

	-- ========================================================================== --
	--                            TELEPORT TAB                                     --
	-- ========================================================================== --

	local TeleportLeftBox = Tabs.Teleport:AddLeftTabbox()
	local TeleportRightBox = Tabs.Teleport:AddRightTabbox()

	local TeleportLeft = TeleportLeftBox:AddTab("Module")
	local TeleportLeft2 = TeleportLeftBox:AddTab("Quick TP")
	local TeleportRight = TeleportRightBox:AddTab("Objectives")
	local TeleportRight2 = TeleportRightBox:AddTab("Players")
	local TeleportCursorGroup = TeleportRightBox:AddTab("Cursor TP")

	-- MODULE STATUS
	local moduleStatusLabel = TeleportLeft:AddLabel("Loading module info...", true)

	local function updateModuleStatus()
		local mapName = TeleportModule.GetCurrentMap()
		local isLoaded = TeleportModule.IsLoaded()
		local hasMap = isLoaded and TeleportModule.HasMapData(mapName)
		local mapCount = TeleportModule.GetMapCount()
		local lastUpdate = TeleportModule.GetLastUpdate()

		local statusText = ""

		if isLoaded then
			local mapStatus = hasMap and "✅ In Database" or "❌ Not Found"

			-- Cek ketersediaan spot Far & Sky
			local farStatus = "❌"
			local skyStatus = "❌"

			if hasMap then
				if TeleportModule.GetMapSpot(mapName, "Far") then
					farStatus = "✅"
				end
				if TeleportModule.GetMapSpot(mapName, "Sky") then
					skyStatus = "✅"
				end
			end

			-- Susun teks agar sangat rapi
			statusText = string.format(
				"Current Map: %s\nMap Status: %s\nSpots: 📍 Far [%s]  |  ☁️ Sky [%s]\nDatabase: %d maps (%s)",
				mapName,
				mapStatus,
				farStatus,
				skyStatus,
				mapCount,
				lastUpdate
			)
		else
			statusText = "❌ Module Not Loaded\nPlease click Refresh."
		end

		if moduleStatusLabel and moduleStatusLabel.SetText then
			pcall(function()
				moduleStatusLabel:SetText(statusText)
			end)
		end
	end

	task.spawn(function()
		while true do
			pcall(updateModuleStatus)
			task.wait(2)
		end
	end)

	TeleportLeft:AddButton({
		Text = "Refresh Teleport Module",
		Tooltip = "Update map database dari GitHub",
		Func = function()
			local success = TeleportModule.Refresh()
			if success then
				updateModuleStatus()
				Success("Teleport Module", "Database berhasil diupdate!", 2)
			end
		end,
	})

	TeleportLeft:AddDivider()

	TeleportLeft:AddToggle("AutoPlaceTeleporter", {
		Text = "Auto Place Every Round",
		Tooltip = "Otomatis place teleporter setiap ronde mulai",
		Default = false,
	})

	Toggles.AutoPlaceTeleporter:OnChanged(function()
		autoPlaceTeleporterEnabled = Toggles.AutoPlaceTeleporter.Value
		if autoPlaceTeleporterEnabled then
			Success("Auto Place", "Akan place " .. autoPlaceTeleporterType .. " teleporter setiap ronde", 3)
		end
	end)

	TeleportLeft:AddDropdown("TeleporterType", {
		Values = { "Far", "Sky" },
		Default = "Far",
		Text = "Teleporter Type",
		Tooltip = "Pilih tipe teleporter (Far / Sky)",
		Callback = function(Value)
			autoPlaceTeleporterType = Value
			Library:Notify({
				Title = "Type Changed",
				Description = "Auto place akan menggunakan " .. Value .. " spot",
				Time = 2,
			})
		end,
	})

	-- QUICK TELEPORTS
	TeleportLeft2:AddButton({
		Text = "Teleport to Far",
		Tooltip = "Teleport player ke spot Far",
		Func = function()
			TeleportModule.TeleportPlayer("Far")
		end,
	})

	TeleportLeft2:AddButton({
		Text = "Teleport to Sky",
		Tooltip = "Teleport player ke spot Sky",
		Func = function()
			TeleportModule.TeleportPlayer("Sky")
		end,
	})

	TeleportLeft2:AddDivider()

	TeleportLeft2:AddButton({
		Text = "Place Teleporter (Far)",
		Tooltip = "Place di spot Far untuk map saat ini",
		Func = function()
			TeleportModule.PlaceTeleporter("Far")
		end,
	})

	TeleportLeft2:AddButton({
		Text = "Place Teleporter (Sky)",
		Tooltip = "Place di spot Sky untuk map saat ini",
		Func = function()
			TeleportModule.PlaceTeleporter("Sky")
		end,
	})

	TeleportLeft2:AddLabel("Place Far Keybind"):AddKeyPicker("PlaceFarKey", {
		Default = "",
		Text = "Place Teleporter (Far) Keybind",
		Mode = "Press",
		Callback = function()
			TeleportModule.PlaceTeleporter("Far")
		end,
	})

	TeleportLeft2:AddLabel("Place Sky Keybind"):AddKeyPicker("PlaceSkyKey", {
		Default = "",
		Text = "Place Teleporter (Sky) Keybind",
		Mode = "Press",
		Callback = function()
			TeleportModule.PlaceTeleporter("Sky")
		end,
	})

	-- ==================== FLOATING MOBILE BTN (QUICK TP) ====================
	local function createQuickTPMobileBtn(name, text, posY, cb)
		local sg = Instance.new("ScreenGui")
		sg.Name = name
		sg.ResetOnSpawn = false
		sg.Enabled = false
		pcall(function()
			sg.Parent = gethui()
		end)
		if not sg.Parent then
			sg.Parent = game:GetService("CoreGui")
		end

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 110, 0, 30)
		btn.Position = UDim2.new(0, 10, 0, posY)
		btn.Font = Enum.Font.Code
		btn.TextSize = 12
		btn.Text = text
		btn.AutoButtonColor = false
		btn.Parent = sg

		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = btn

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = btn

		local drag, ds, sp
		btn.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				drag = true
				ds = i.Position
				sp = btn.Position
			end
		end)
		btn.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				drag = false
			end
		end)
		game:GetService("UserInputService").InputChanged:Connect(function(i)
			if
				(i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch)
				and drag
			then
				btn.Position = UDim2.new(
					sp.X.Scale,
					sp.X.Offset + (i.Position.X - ds.X),
					sp.Y.Scale,
					sp.Y.Offset + (i.Position.Y - ds.Y)
				)
			end
		end)
		btn.MouseButton1Click:Connect(cb)

		return sg, btn, stroke
	end

	-- 1. Tombol Teleport
	local tpFarMobileGui, tpFarMobileBtn, tpFarMobileStroke = createQuickTPMobileBtn(
		"TPFarBtn",
		"TP Far",
		380,
		function()
			TeleportModule.TeleportPlayer("Far")
		end
	)

	local tpSkyMobileGui, tpSkyMobileBtn, tpSkyMobileStroke = createQuickTPMobileBtn(
		"TPSkyBtn",
		"TP Sky",
		420,
		function()
			TeleportModule.TeleportPlayer("Sky")
		end
	)

	-- 2. Tombol Place Teleporter
	local placeFarMobileGui, placeFarMobileBtn, placeFarMobileStroke = createQuickTPMobileBtn(
		"PlaceFarBtn",
		"Place TP Far",
		460,
		function()
			TeleportModule.PlaceTeleporter("Far")
		end
	)

	local placeSkyMobileGui, placeSkyMobileBtn, placeSkyMobileStroke = createQuickTPMobileBtn(
		"PlaceSkyBtn",
		"Place TP Sky",
		500,
		function()
			TeleportModule.PlaceTeleporter("Sky")
		end
	)

	-- ZERO DELAY SYNC WARNA (Loop untuk ke-4 tombol)
	game:GetService("RunService").Heartbeat:Connect(function()
		local font = (Options and Options.FontColor and Options.FontColor.Value)
			or (Library and typeof(Library.FontColor) == "Color3" and Library.FontColor)
			or Color3.fromRGB(200, 200, 200)
		local main = (Options and Options.MainColor and Options.MainColor.Value)
			or (Library and typeof(Library.MainColor) == "Color3" and Library.MainColor)
			or Color3.fromRGB(20, 20, 20)
		local outline = (Options and Options.OutlineColor and Options.OutlineColor.Value)
			or (Library and typeof(Library.OutlineColor) == "Color3" and Library.OutlineColor)
			or Color3.fromRGB(45, 45, 45)

		local btns = {
			{ gui = tpFarMobileGui, btn = tpFarMobileBtn, stroke = tpFarMobileStroke },
			{ gui = tpSkyMobileGui, btn = tpSkyMobileBtn, stroke = tpSkyMobileStroke },
			{ gui = placeFarMobileGui, btn = placeFarMobileBtn, stroke = placeFarMobileStroke },
			{ gui = placeSkyMobileGui, btn = placeSkyMobileBtn, stroke = placeSkyMobileStroke },
		}

		for _, obj in ipairs(btns) do
			if obj.gui and obj.gui.Parent and obj.btn then
				obj.btn.TextColor3 = font
				obj.btn.BackgroundColor3 = main
				obj.stroke.Color = outline
			end
		end
	end)

	TeleportLeft2:AddDivider()

	-- Menambahkan Toggle Menu ke Linoria
	TeleportLeft2:AddToggle("ShowMobileTPFar", { Text = "Show Mobile TP Far", Default = false })
	Toggles.ShowMobileTPFar:OnChanged(function()
		tpFarMobileGui.Enabled = Toggles.ShowMobileTPFar.Value
	end)

	TeleportLeft2:AddToggle("ShowMobileTPSky", { Text = "Show Mobile TP Sky", Default = false })
	Toggles.ShowMobileTPSky:OnChanged(function()
		tpSkyMobileGui.Enabled = Toggles.ShowMobileTPSky.Value
	end)

	TeleportLeft2:AddToggle("ShowMobilePlaceFar", { Text = "Show Mobile Place Far", Default = false })
	Toggles.ShowMobilePlaceFar:OnChanged(function()
		placeFarMobileGui.Enabled = Toggles.ShowMobilePlaceFar.Value
	end)

	TeleportLeft2:AddToggle("ShowMobilePlaceSky", { Text = "Show Mobile Place Sky", Default = false })
	Toggles.ShowMobilePlaceSky:OnChanged(function()
		placeSkyMobileGui.Enabled = Toggles.ShowMobilePlaceSky.Value
	end)

	-- OBJECTIVE TELEPORTS
	TeleportRight:AddButton({
		Text = "Teleport to Objective",
		Tooltip = "Teleport ke objective random",
		Func = function()
			TeleportFeaturesModule.TeleportToRandomObjective()
		end,
	})

	TeleportRight:AddButton({
		Text = "Teleport to Nearest Ticket",
		Tooltip = "Teleport ke ticket terdekat",
		Func = function()
			TeleportFeaturesModule.TeleportToNearestTicket()
		end,
	})

	-- PLAYER TELEPORTS
	local selectedPlayerName = nil

	local function refreshPlayerList()
		local playerList = TeleportFeaturesModule.GetPlayerList()
		if Options.PlayerDropdown then
			Options.PlayerDropdown:SetValues(playerList)
			if #playerList > 0 and playerList[1] ~= "No players available" then
				if not selectedPlayerName or not table.find(playerList, selectedPlayerName) then
					selectedPlayerName = playerList[1]
					Options.PlayerDropdown:SetValue(selectedPlayerName)
				end
			else
				selectedPlayerName = nil
			end
		end
	end

	TeleportRight2:AddDropdown("PlayerDropdown", {
		Values = { "Loading..." },
		Default = "Loading...",
		Multi = false,
		Text = "Select Player",
		Tooltip = "Pilih player untuk teleport",
		Searchable = true,
		Callback = function(Value)
			if Value and Value ~= "No players available" and Value ~= "Loading..." then
				selectedPlayerName = Value
			end
		end,
	})

	task.spawn(function()
		task.wait(1)
		refreshPlayerList()
	end)

	Players.PlayerAdded:Connect(function()
		task.wait(1)
		refreshPlayerList()
	end)

	Players.PlayerRemoving:Connect(function()
		task.wait(0.5)
		refreshPlayerList()
	end)

	TeleportRight2:AddButton({
		Text = "Teleport to Selected Player",
		Tooltip = "Teleport ke player yang dipilih",
		Func = function()
			if selectedPlayerName and selectedPlayerName ~= "No players available" then
				TeleportFeaturesModule.TeleportToPlayer(selectedPlayerName)
			else
				Error("Teleport", "Pilih player terlebih dahulu!", 2)
			end
		end,
	})

	TeleportRight2:AddButton({
		Text = "Refresh Player List",
		Tooltip = "Update daftar player manual",
		Func = function()
			refreshPlayerList()
			Info("Player List", "Daftar player diupdate!", 2)
		end,
	})

	TeleportRight2:AddButton({
		Text = "Teleport to Random Player",
		Tooltip = "Teleport ke player random",
		Func = function()
			TeleportFeaturesModule.TeleportToRandomPlayer()
		end,
	})

	TeleportRight2:AddDivider()

	TeleportRight2:AddButton({
		Text = "Teleport to Nearest Downed",
		Tooltip = "Teleport ke player downed terdekat",
		Func = function()
			TeleportFeaturesModule.TeleportToNearestDowned()
		end,
	})

	-- ==================== DASH / CURSOR TELEPORT ====================
	local cursorTpDistance = 10
	local cursorTpDirection = "Towards Cursor"

	TeleportCursorGroup:AddToggle("EnableCursorTP", {
		Text = "Enable Teleport",
		Default = false,
		Tooltip = "Enable this safety toggle before using the teleport keybind",
	})
	TeleportCursorGroup:AddDropdown("CursorTPDirection", {
		Values = { "Forward", "Backward", "Towards Cursor" },
		Default = "Towards Cursor",
		Multi = false,
		Text = "Teleport Direction",
		Callback = function(Value)
			cursorTpDirection = Value
		end,
	})
	TeleportCursorGroup:AddSlider("CursorTPDistSlider", {
		Text = "Teleport Distance (Studs)",
		Default = 10,
		Min = 1,
		Max = 100,
		Rounding = 1,
		Compact = false,
		Callback = function(Value)
			cursorTpDistance = Value
			if Options.CursorTPDistInput then
				Options.CursorTPDistInput:SetValue(tostring(Value))
			end
		end,
	})
	TeleportCursorGroup:AddInput("CursorTPDistInput", {
		Default = "10",
		Numeric = true,
		Finished = true,
		Text = "Manual Distance Input",
		Placeholder = "1-100",
		Callback = function(Value)
			local num = tonumber(Value)
			if num then
				num = math.clamp(num, 1, 100)
				if Options.CursorTPDistSlider then
					Options.CursorTPDistSlider:SetValue(num)
				end
				cursorTpDistance = num
			end
		end,
	})
	TeleportCursorGroup:AddDivider()

	local function ExecuteCursorTP()
		if not Toggles.EnableCursorTP.Value then
			if Library and Library.Notify then
				Library:Notify({
					Title = "Cursor TP",
					Description = "Nyalakan toggle Enable Teleport dulu di menu!",
					Time = 2,
				})
			end
			return
		end

		local player = game:GetService("Players").LocalPlayer
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end

		if cursorTpDirection == "Forward" then
			hrp.CFrame = hrp.CFrame + (hrp.CFrame.LookVector * cursorTpDistance)
		elseif cursorTpDirection == "Backward" then
			hrp.CFrame = hrp.CFrame + (-hrp.CFrame.LookVector * cursorTpDistance)
		elseif cursorTpDirection == "Towards Cursor" then
			local mouse = player:GetMouse()
			if not mouse.Hit then
				return
			end
			local direction = (mouse.Hit.Position - hrp.Position)
			if direction.Magnitude > 0 then
				hrp.CFrame = hrp.CFrame + (direction.Unit * cursorTpDistance)
			end
		end
	end

	TeleportCursorGroup:AddLabel("Teleport Keybind"):AddKeyPicker(
		"CursorTPKey",
		{ Default = "", SyncToggleState = false, Mode = "Press", Text = "Execute Teleport", Callback = ExecuteCursorTP }
	)

	local function createCursorTPMobileBtn()
		local sg = Instance.new("ScreenGui")
		sg.Name = "TPMobileBtn"
		sg.ResetOnSpawn = false
		sg.Enabled = false
		pcall(function()
			sg.Parent = gethui()
		end)
		if not sg.Parent then
			sg.Parent = game:GetService("CoreGui")
		end
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 110, 0, 30)
		btn.Position = UDim2.new(0, 10, 0, 100)
		btn.Font = Enum.Font.Code
		btn.TextSize = 12
		btn.Text = "Cursor TP"
		btn.AutoButtonColor = false
		btn.Parent = sg
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = btn
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		local drag, ds, sp
		btn.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				drag = true
				ds = i.Position
				sp = btn.Position
			end
		end)
		btn.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				drag = false
			end
		end)
		game:GetService("UserInputService").InputChanged:Connect(function(i)
			if
				(i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch)
				and drag
			then
				btn.Position = UDim2.new(
					sp.X.Scale,
					sp.X.Offset + (i.Position.X - ds.X),
					sp.Y.Scale,
					sp.Y.Offset + (i.Position.Y - ds.Y)
				)
			end
		end)
		btn.MouseButton1Click:Connect(ExecuteCursorTP)
		return sg, btn, stroke
	end

	local tpMobileGui, tpMobileBtn, tpMobileStroke = createCursorTPMobileBtn()

	-- ZERO DELAY SYNC
	game:GetService("RunService").Heartbeat:Connect(function()
		if tpMobileGui and tpMobileGui.Parent and tpMobileBtn then
			local font = (Options and Options.FontColor and Options.FontColor.Value)
				or (Library and typeof(Library.FontColor) == "Color3" and Library.FontColor)
				or Color3.fromRGB(200, 200, 200)
			local main = (Options and Options.MainColor and Options.MainColor.Value)
				or (Library and typeof(Library.MainColor) == "Color3" and Library.MainColor)
				or Color3.fromRGB(20, 20, 20)
			local outline = (Options and Options.OutlineColor and Options.OutlineColor.Value)
				or (Library and typeof(Library.OutlineColor) == "Color3" and Library.OutlineColor)
				or Color3.fromRGB(45, 45, 45)

			tpMobileBtn.TextColor3 = font
			tpMobileBtn.BackgroundColor3 = main
			tpMobileStroke.Color = outline
		end
	end)

	TeleportCursorGroup:AddToggle("ShowMobileCursorTP", { Text = "Show Mobile TP Button", Default = false })
	Toggles.ShowMobileCursorTP:OnChanged(function()
		tpMobileGui.Enabled = Toggles.ShowMobileCursorTP.Value
	end)
	TeleportCursorGroup:AddLabel(
		"Tip: 'Forward' and 'Backward' are based on where your character is currently facing.",
		true
	)

	-- ========================================================================== --
	--                           ESP TAB (TABBOX VERSION)                         --
	-- ========================================================================== --

	-- 1. MEMBUAT TABBOX KIRI (Untuk Entities)
	local ESPLeftTabbox = Tabs.ESP:AddLeftTabbox()
	local TabPlayers = ESPLeftTabbox:AddTab("Players")
	local TabTickets = ESPLeftTabbox:AddTab("Tickets")
	local TabNextbots = ESPLeftTabbox:AddTab("Nextbots")

	-- Master Control kita jadikan Groupbox biasa di bawah Tabbox Kiri
	local ESPMasterGroup = Tabs.ESP:AddLeftGroupbox("Master Control", "settings")

	-- 2. MEMBUAT TABBOX KANAN (Untuk Visual Modifiers)
	local ESPRightTabbox = Tabs.ESP:AddRightTabbox()
	local TabChams = ESPRightTabbox:AddTab("Chams")
	local TabTracers = ESPRightTabbox:AddTab("Tracers")

	-- ==================== ISI TAB PLAYERS ====================
	TabPlayers:AddToggle("PlayersESP", {
		Text = "Players ESP",
		Tooltip = "Tampilkan nama + jarak + status player lain",
		Default = false,
	}):AddKeyPicker("ESPPlayersKey", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Players ESP" })

	Toggles.PlayersESP:OnChanged(function()
		ESP_System.Settings.Players.Enabled = Toggles.PlayersESP.Value
		if Toggles.PlayersESP.Value then
			if not ESP_System.Running then
				ESP_System:Start()
			end
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					ESP_System:CreatePlayerESP(p)
				end
			end
			Success("Players ESP", "Aktif", 2)
		else
			ESP_System:ClearPlayersESP()
			if not ESP_System.Settings.Tickets.Enabled and not ESP_System.Settings.Nextbots.Enabled then
				ESP_System:Stop()
			end
			Info("Players ESP", "Dimatikan", 2)
		end
	end)

	TabPlayers:AddDropdown("PlayersESPColor", {
		Values = { "Putih", "Merah", "Hijau", "Biru", "Kuning", "Pink", "Cyan" },
		Default = "Putih",
		Text = "ESP Color",
		Tooltip = "Pilih warna label player",
		Callback = function(Value)
			local colors = {
				Putih = Color3.fromRGB(255, 255, 255),
				Merah = Color3.fromRGB(255, 50, 50),
				Hijau = Color3.fromRGB(50, 255, 50),
				Biru = Color3.fromRGB(50, 150, 255),
				Kuning = Color3.fromRGB(255, 255, 0),
				Pink = Color3.fromRGB(255, 100, 255),
				Cyan = Color3.fromRGB(0, 255, 255),
			}
			ESP_System.Settings.Players.Color = colors[Value] or Color3.fromRGB(255, 255, 255)
		end,
	})
	TabPlayers:AddLabel("Info: Putih=normal, Merah=downed, Kuning=reviving", true)

	-- ==================== ISI TAB TICKETS ====================
	TabTickets:AddToggle("TicketsESP", {
		Text = "Tickets ESP",
		Tooltip = "Tampilkan lokasi + jarak ticket di map",
		Default = false,
	}):AddKeyPicker("ESPTicketsKey", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Tickets ESP" })

	Toggles.TicketsESP:OnChanged(function()
		ESP_System.Settings.Tickets.Enabled = Toggles.TicketsESP.Value
		if Toggles.TicketsESP.Value then
			if not ESP_System.Running then
				ESP_System:Start()
			end
			Success("Tickets ESP", "Aktif", 2)
		else
			ESP_System:ClearTicketsESP()
			if not ESP_System.Settings.Players.Enabled and not ESP_System.Settings.Nextbots.Enabled then
				ESP_System:Stop()
			end
			Info("Tickets ESP", "Dimatikan", 2)
		end
	end)

	TabTickets:AddDropdown("TicketsESPColor", {
		Values = { "Oranye", "Putih", "Kuning", "Hijau", "Pink" },
		Default = "Oranye",
		Text = "Ticket Color",
		Callback = function(Value)
			local colors = {
				Oranye = Color3.fromRGB(255, 165, 0),
				Putih = Color3.fromRGB(255, 255, 255),
				Kuning = Color3.fromRGB(255, 255, 0),
				Hijau = Color3.fromRGB(50, 255, 50),
				Pink = Color3.fromRGB(255, 100, 255),
			}
			ESP_System.Settings.Tickets.Color = colors[Value] or Color3.fromRGB(255, 165, 0)
		end,
	})

	-- ==================== ISI TAB NEXTBOTS ====================
	TabNextbots:AddToggle("NextbotsESP", {
		Text = "Nextbots ESP",
		Tooltip = "Tampilkan lokasi + jarak nextbot/monster",
		Default = false,
	}):AddKeyPicker("ESPNextbotsKey", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Nextbots ESP" })

	Toggles.NextbotsESP:OnChanged(function()
		ESP_System.Settings.Nextbots.Enabled = Toggles.NextbotsESP.Value
		if Toggles.NextbotsESP.Value then
			if not ESP_System.Running then
				ESP_System:Start()
			end
			Success("Nextbots ESP", "Aktif", 2)
		else
			ESP_System:ClearNextbotsESP()
			if not ESP_System.Settings.Players.Enabled and not ESP_System.Settings.Tickets.Enabled then
				ESP_System:Stop()
			end
			Info("Nextbots ESP", "Dimatikan", 2)
		end
	end)

	TabNextbots:AddDropdown("NextbotsESPColor", {
		Values = { "Merah", "Oranye", "Putih", "Kuning", "Pink" },
		Default = "Merah",
		Text = "Nextbot Color",
		Callback = function(Value)
			local colors = {
				Merah = Color3.fromRGB(255, 50, 50),
				Oranye = Color3.fromRGB(255, 165, 0),
				Putih = Color3.fromRGB(255, 255, 255),
				Kuning = Color3.fromRGB(255, 255, 0),
				Pink = Color3.fromRGB(255, 100, 255),
			}
			ESP_System.Settings.Nextbots.Color = colors[Value] or Color3.fromRGB(255, 50, 50)
		end,
	})

	-- ==================== ISI TAB CHAMS ====================
	TabChams:AddToggle("ChamsPlayers", {
		Text = "Chams Players",
		Tooltip = "Highlight player terlihat melalui tembok",
		Default = false,
	})

	Toggles.ChamsPlayers:OnChanged(function()
		ESP_System.Settings.ChamsPlayers.Enabled = Toggles.ChamsPlayers.Value
		if Toggles.ChamsPlayers.Value then
			if not ESP_System.Running then
				ESP_System:Start()
			end
			Success("Chams", "Players Chams aktif", 2)
		else
			ESP_System:ClearPlayerChams()
			Info("Chams", "Players Chams dimatikan", 2)
		end
	end)

	TabChams:AddDropdown("ChamsFillColor", {
		Values = { "Merah", "Biru", "Hijau", "Kuning", "Pink", "Cyan", "Putih", "Oranye" },
		Default = "Merah",
		Text = "Fill Color",
		Callback = function(Value)
			local colors = {
				Merah = Color3.fromRGB(255, 0, 0),
				Biru = Color3.fromRGB(0, 100, 255),
				Hijau = Color3.fromRGB(0, 255, 0),
				Kuning = Color3.fromRGB(255, 255, 0),
				Pink = Color3.fromRGB(255, 0, 255),
				Cyan = Color3.fromRGB(0, 255, 255),
				Putih = Color3.fromRGB(255, 255, 255),
				Oranye = Color3.fromRGB(255, 165, 0),
			}
			ESP_System.Settings.ChamsPlayers.FillColor = colors[Value] or Color3.fromRGB(255, 0, 0)
		end,
	})

	TabChams:AddDropdown("ChamsOutlineColor", {
		Values = { "Putih", "Kuning", "Merah", "Cyan", "Hijau" },
		Default = "Putih",
		Text = "Outline Color",
		Callback = function(Value)
			local colors = {
				Putih = Color3.fromRGB(255, 255, 255),
				Kuning = Color3.fromRGB(255, 255, 0),
				Merah = Color3.fromRGB(255, 0, 0),
				Cyan = Color3.fromRGB(0, 255, 255),
				Hijau = Color3.fromRGB(0, 255, 0),
			}
			ESP_System.Settings.ChamsPlayers.OutlineColor = colors[Value] or Color3.fromRGB(255, 255, 255)
		end,
	})

	TabChams:AddDropdown("ChamsTransparency", {
		Values = { "Solid (0%)", "Tipis (30%)", "Setengah (50%)", "Transparan (70%)" },
		Default = "Setengah (50%)",
		Text = "Transparency",
		Callback = function(Value)
			local levels =
				{ ["Solid (0%)"] = 0, ["Tipis (30%)"] = 0.3, ["Setengah (50%)"] = 0.5, ["Transparan (70%)"] = 0.7 }
			ESP_System.Settings.ChamsPlayers.FillTransparency = levels[Value] or 0.5
		end,
	})

	-- ==================== ISI TAB TRACERS ====================
	TabTracers:AddToggle("TracerDowned", { Text = "Tracer Downed Only", Default = false })
	Toggles.TracerDowned:OnChanged(function()
		ESP_System.Settings.TracerDowned.Enabled = Toggles.TracerDowned.Value
		if Toggles.TracerDowned.Value then
			if not ESP_System.Running then
				ESP_System:Start()
			end
		else
			ESP_System:ClearTracerDowned()
		end
	end)

	TabTracers:AddToggle("TracerAll", { Text = "Tracer All Players", Default = false })
	Toggles.TracerAll:OnChanged(function()
		ESP_System.Settings.TracerAll.Enabled = Toggles.TracerAll.Value
		if Toggles.TracerAll.Value then
			if not ESP_System.Running then
				ESP_System:Start()
			end
		else
			ESP_System:ClearTracerAll()
		end
	end)

	TabTracers:AddDivider()

	TabTracers:AddDropdown("TracerAllThickness", {
		Values = { "Tipis (1)", "Normal (2)", "Tebal (3)" },
		Default = "Normal (2)",
		Text = "Line Thickness",
		Callback = function(Value)
			local thickness = { ["Tipis (1)"] = 1, ["Normal (2)"] = 2, ["Tebal (3)"] = 3 }
			ESP_System.Settings.TracerAll.Thickness = thickness[Value] or 2
			ESP_System.Settings.TracerDowned.Thickness = thickness[Value] or 2
		end,
	})

	-- ==================== MASTER CONTROL (GROUPBOX BIASA) ====================
	ESPMasterGroup:AddButton({
		Text = "Enable All ESP",
		Tooltip = "Aktifkan semua ESP sekaligus",
		Func = function()
			Toggles.PlayersESP:SetValue(true)
			Toggles.TicketsESP:SetValue(true)
			Toggles.NextbotsESP:SetValue(true)
			Success("ESP", "Semua ESP diaktifkan!", 2)
		end,
	})

	ESPMasterGroup:AddButton({
		Text = "Disable All ESP",
		Tooltip = "Matikan semua ESP sekaligus",
		Func = function()
			Toggles.PlayersESP:SetValue(false)
			Toggles.TicketsESP:SetValue(false)
			Toggles.NextbotsESP:SetValue(false)
			Info("ESP", "Semua ESP dimatikan!", 2)
		end,
	})

	-- ========================================================================== --
	--                             EMOTES TAB                                     --
	-- ========================================================================== --

	local EmotesLeftBox = Tabs.Emotes:AddLeftTabbox()
	local EmotesRightBox = Tabs.Emotes:AddRightTabbox()

	local EmoteChangerGroup = EmotesLeftBox:AddTab("Replacer")
	local EmoteControlsGroup = EmotesRightBox:AddTab("Controls")

	EmoteChangerGroup:AddLabel("Ganti emote gratisan jadi yang mahal! (5 Slot)", true)
	EmoteChangerGroup:AddDivider()

	local emoteList = {
		"None",
		"APose",
		"Addendum",
		"Aerobics",
		"AngelicWings",
		"AprilShower",
		"AuspiciousWell",
		"AvariceLounge",
		"BeachChairLounge",
		"Beg",
		"Bhop",
		"BobointheBox",
		"BoldMarch",
		"Boneless",
		"BoogieDown",
		"Breakdown",
		"BringItAround",
		"Broom",
		"Bumblebee",
		"BumperKart",
		"Caffeinated",
		"California",
		"CampfireDoze",
		"Caramelldansen",
		"Carlton",
		"CasualSurfing",
		"CatDance",
		"CatParty",
		"Catdown",
		"Catjam",
		"ChristmasBoogie",
		"Clap",
		"ClassicDance",
		"ClassicJeep",
		"ClassicStride",
		"ClubDance",
		"CompanyMan",
		"Conga",
		"CozyChair",
		"Crabby",
		"CrouchDance",
		"CuerdasDelAlma",
		"CyberBroom",
		"DeadBoneStride",
		"Distraction",
		"DogParty",
		"DreamyCloud",
		"DuckyMarch",
		"DynastyDrumming",
		"Epicaricacy",
		"Facepalm",
		"FastFoodDelight",
		"Fazbore",
		"FireworkBlast",
		"FlashingLights",
		"Flexing",
		"FlyingFish",
		"FlyingSleigh",
		"Freestyle",
		"FreshFlop",
		"FrightFunk",
		"Frolic",
		"FrostDrake",
		"Gangnam",
		"GhastlyGrimoire",
		"GhoulishGalleon",
		"Gmod",
		"GoldRitual",
		"GoofyStride",
		"GraveRider",
		"Griddy",
		"Gyrating",
		"HarpRecital",
		"HeadlessBaller",
		"HeadlessHorseman",
		"Heaventaker",
		"Hired",
		"HoveringCrystal",
		"IceFishing",
		"Infectious",
		"IrishJig",
		"Kickback",
		"LDance",
		"LemonadeStand",
		"LineDance",
		"LittleJiggy",
		"LunarParty",
		"M3GANDance",
		"Macarena",
		"ManyFans",
		"MaracaTime",
		"MarchShowcase",
		"Marching",
		"MariachiBand",
		"Mashle",
		"Moonwalk",
		"Nizmoo",
		"Nostalgia",
		"Nutcracker",
		"OiiaOiia",
		"PBJT",
		"ParkerPride",
		"PawsClaws",
		"PonPon",
		"PoolTime",
		"Popipopi",
		"PotionMash",
		"PumpItUp",
		"RainingTacos",
		"Rambunctious",
		"Reanimated",
		"Robot",
		"RobotM3GAN",
		"RockefellerStreet",
		"Rocket",
		"RockinStride",
		"RockingHorse",
		"RowBoat",
		"RudolphMount",
		"RushinAround",
		"RussianDance",
		"SantaMech",
		"ScorchedEarth",
		"SeeTinh",
		"SerenePerch",
		"SeriousMarch",
		"ShubaDance",
		"Sit",
		"SkateboardStroll",
		"SkiSpree",
		"SledDrifting",
		"Sleep",
		"Sleepybara",
		"Smile",
		"Smug",
		"SnowAngel",
		"SnowmanConstruction",
		"SnowmobileCruise",
		"SolarBike",
		"SolarConqueror",
		"SolarSlayer",
		"SpiritedAway",
		"SpookyTime",
		"StarPower",
		"Stride",
		"SummerDays",
		"SwagWalk",
		"TPose",
		"Tank",
		"TexasStyle",
		"Thriller",
		"TouchGrass",
		"ToyTrainRide",
		"TurkeyJockey",
		"TurtleHobble",
		"Twist",
		"ValentineComputer",
		"WerewolfHowl",
		"Wess",
		"WindUpPose",
		"WindupDance",
		"WinterMelody",
		"WinterRide",
		"Writhing",
		"Xylobone",
		"ZenSerenity",
		"ZombieStride",
	}

	for i = 1, 5 do
		EmoteChangerGroup:AddDropdown("CurrentEmote" .. i, {
			Values = emoteList,
			Default = 1,
			Multi = false,
			Searchable = true,
			Text = "Slot " .. i .. " - Emote Aslimu",
			Tooltip = "Pilih emote gratisan yang kamu miliki",
			Callback = function(Value)
				EmoteChangerModule.SetCurrent(i, Value == "None" and "" or Value)
			end,
		})

		EmoteChangerGroup:AddDropdown("TargetEmote" .. i, {
			Values = emoteList,
			Default = 1,
			Multi = false,
			Searchable = true,
			Text = "Slot " .. i .. " - Emote Target",
			Tooltip = "Pilih emote mewah yang ingin dimainkan",
			Callback = function(Value)
				EmoteChangerModule.SetSelect(i, Value == "None" and "" or Value)
			end,
		})

		if i < 5 then
			EmoteChangerGroup:AddDivider()
		end
	end

	EmoteControlsGroup:AddButton({
		Text = "Apply Emote Mappings",
		Tooltip = "Mulai proses manipulasi emote",
		Func = function()
			local success, msg = EmoteChangerModule.Apply()
			if success then
				Success("Emote Changer", msg, 3)
			else
				Error("Emote Changer", msg, 3)
			end
		end,
	})

	EmoteControlsGroup:AddButton({
		Text = "Reset Mappings",
		Tooltip = "Bersihkan semua slot",
		Func = function()
			EmoteChangerModule.Reset()
			for i = 1, 5 do
				Options["CurrentEmote" .. i]:SetValue("None")
				Options["TargetEmote" .. i]:SetValue("None")
			end
			Info("Emote Changer", "Semua pengaturan di-reset!", 2)
		end,
	})

	EmoteControlsGroup:AddDivider()

	-- ==================== EMOTE POSSIBLE OPTION ====================
	local currentEmoteNum = 1

	EmoteControlsGroup:AddInput("EmoteNumOption", {
		Default = "1",
		Numeric = true,
		Finished = false,
		Text = "Emote Possible Option",
		Tooltip = "Angka lebih tinggi bisa merusak animasi (Rekomendasi 1-3)",
		Placeholder = "1",
		Callback = function(Value)
			local num = tonumber(Value)
			if num then
				currentEmoteNum = num
				local char = game:GetService("Players").LocalPlayer.Character
				if char then
					char:SetAttribute("EmoteNum", currentEmoteNum)
				end
			end
		end,
	})

	EmoteControlsGroup:AddLabel("💡 Info: Mengubah variasi emote.", true)

	-- Loop yang bekerja di latar belakang untuk terus menerapkan EmoteNum (Persis script asli)
	task.spawn(function()
		while true do
			task.wait(1)
			local char = game:GetService("Players").LocalPlayer.Character
			if char and char:GetAttribute("EmoteNum") ~= currentEmoteNum then
				char:SetAttribute("EmoteNum", currentEmoteNum)
			end
		end
	end)

	-- ===============================================================

	EmoteControlsGroup:AddDivider()
	EmoteControlsGroup:AddLabel(
		"⚠️ Catatan:\nGambar icon emote di game TIDAK AKAN BERUBAH. Ini wajar dan membuktikan bypass aman!",
		true
	)

	-- ========================================================================== --
	--                             AUTO FARM TAB (V3.2)                           --
	-- ========================================================================== --

	local FarmLeftBox = Tabs.AutoFarm:AddLeftTabbox()
	local FarmRightBox = Tabs.AutoFarm:AddRightTabbox()

	local AutoFarmLeft = FarmLeftBox:AddTab("Main Farm")
	local AutoFarmRight = FarmRightBox:AddTab("Idle Mode")

	-- 1. DEFINE TOGGLES (Membuat Tombol di Menu)
	AutoFarmLeft:AddToggle("AutoFarmMoney", {
		Text = "Auto Farm Money",
		Default = false,
		Tooltip = "Teleport ke player downed untuk cari uang",
	})

	AutoFarmLeft:AddToggle("AutoFarmTickets", {
		Text = "Auto Farm Tickets",
		Default = false,
		Tooltip = "Otomatis ambil ticket event (Hanya saat Event aktif)",
	})

	AutoFarmRight:AddToggle("AFKFarm", {
		Text = "AFK Farm (Auto Win)",
		Default = false,
		Tooltip = "Diam aman di langit untuk farm XP & Win",
	})

	AutoFarmRight:AddToggle("AntiAFKToggle", {
		Text = "Anti-AFK (No Kick)",
		Default = false,
		Tooltip = "Mencegah Roblox mengeluarkanmu (Kick) jika diam lebih dari 20 menit",
	})

	Toggles.AntiAFKToggle:OnChanged(function()
		if Toggles.AntiAFKToggle.Value then
			AntiAFKModule.Start()
		else
			AntiAFKModule.Stop()
		end
	end)
	-- 2. LOGIC HANDLERS (Menghubungkan Tombol ke Unified Module)

	-- Logika Money Farm
	Toggles.AutoFarmMoney:OnChanged(function()
		if Toggles.AutoFarmMoney.Value then
			-- Matikan toggle lain agar tidak berebutan posisi teleport
			Toggles.AutoFarmTickets:SetValue(false, true) -- 'true' agar tidak memicu loop callback
			Toggles.AFKFarm:SetValue(false, true)
			UnifiedAutoFarm.SetMode("Money")
		else
			if UnifiedAutoFarm.GetMode() == "Money" then
				UnifiedAutoFarm.SetMode("None")
			end
		end
	end)

	-- Logika Ticket Farm
	Toggles.AutoFarmTickets:OnChanged(function()
		if Toggles.AutoFarmTickets.Value then
			Toggles.AutoFarmMoney:SetValue(false, true)
			Toggles.AFKFarm:SetValue(false, true)
			UnifiedAutoFarm.SetMode("Ticket")
		else
			if UnifiedAutoFarm.GetMode() == "Ticket" then
				UnifiedAutoFarm.SetMode("None")
			end
		end
	end)

	-- Logika AFK Farm
	Toggles.AFKFarm:OnChanged(function()
		if Toggles.AFKFarm.Value then
			Toggles.AutoFarmMoney:SetValue(false, true)
			Toggles.AutoFarmTickets:SetValue(false, true)
			UnifiedAutoFarm.SetMode("AFK")
		else
			if UnifiedAutoFarm.GetMode() == "AFK" then
				UnifiedAutoFarm.SetMode("None")
			end
		end
	end)

	-- Info Labels
	AutoFarmLeft:AddLabel("Status: " .. (UnifiedAutoFarm.GetMode() == "None" and "Idle" or "Active"), true)
	AutoFarmRight:AddLabel("💡 Tip: Jangan aktifkan 2 farm sekaligus!", true)

	-- ========================================================================== --
	--                            PLAYER SETTINGS TAB                              --
	-- ========================================================================== --

	local PlayerLeftBox = Tabs.PlayerSettings:AddLeftTabbox()
	local PlayerRightBox = Tabs.PlayerSettings:AddRightTabbox()

	local PlayerLeft = PlayerLeftBox:AddTab("Movement")
	local PlayerRight = PlayerRightBox:AddTab("View")

	-- PLAYER SPEED
	PlayerLeft:AddInput("PlayerSpeed", {
		Default = "1500",
		Numeric = true,
		Text = "Player Speed",
		Tooltip = "Adjust player movement speed (1450-100000000)",
		Placeholder = "Default: 1500",
		Callback = function(Value)
			PlayerAdjustmentsModule.SetSpeed(Value)
		end,
	})

	-- PLAYER JUMP POWER
	PlayerLeft:AddInput("PlayerJumpPower", {
		Default = "3.5",
		Numeric = true,
		Text = "Jump Power",
		Tooltip = "Adjust jump height (0.1-1000)",
		Placeholder = "Default: 3.5",
		Callback = function(Value)
			JumpPowerModule.SetJumpPower(Value)
		end,
	})

	-- PLAYER JUMP CAP
	PlayerLeft:AddInput("PlayerJumpCap", {
		Default = "1",
		Numeric = true,
		Text = "Jump Cap",
		Tooltip = "Maximum jump velocity (0.1-5000000)",
		Placeholder = "Default: 1",
		Callback = function(Value)
			PlayerAdjustmentsModule.SetJumpCap(Value)
		end,
	})

	-- PLAYER STRAFE ACCELERATION
	PlayerLeft:AddInput("PlayerStrafe", {
		Default = "187",
		Numeric = true,
		Text = "Air Strafe Acceleration",
		Tooltip = "Control movement speed in air (1-1000000000)",
		Placeholder = "Default: 187",
		Callback = function(Value)
			PlayerAdjustmentsModule.SetStrafeAccel(Value)
		end,
	})

	PlayerLeft:AddDivider()

	-- APPLY METHOD
	PlayerLeft:AddDropdown("ApplyMethod", {
		Values = { "Not Optimized", "Optimized" },
		Default = "Not Optimized",
		Text = "Apply Method",
		Tooltip = "Not Optimized = instant apply | Optimized = batched apply (less lag)",
		Callback = function(Value)
			PlayerAdjustmentsModule.SetApplyMode(Value)
		end,
	})

	PlayerLeft:AddLabel("💡 Info:\n• Not Optimized = Instant changes\n• Optimized = Batched (prevents lag)", true)

	-- FOV ADJUSTMENT
	PlayerRight:AddInput("PlayerFOV", {
		Default = "150",
		Numeric = true,
		Text = "Field of View (FOV)",
		Tooltip = "Adjust camera FOV (1-1000)",
		Placeholder = "Default: 150",
		Callback = function(Value)
			FOVModule.SetFOV(Value)
		end,
	})

	PlayerRight:AddLabel(
		"⚠️ FOV Changes:\n• Only applies when you change it\n• Rejoin to reset to default\n• Higher = wider view",
		true
	)

	PlayerRight:AddDivider()

	-- FOV PRESETS
	PlayerRight:AddDropdown("FOVPresets", {
		Values = {
			"100 FOV (150)",
			"110 FOV (200)",
			"120 FOV (250)",
			"130 FOV (300)",
			"140 FOV (350)",
			"150 FOV (400)",
		},
		Default = "100 FOV (150)",
		Text = "FOV Presets",
		Tooltip = "Quick FOV presets",
		Callback = function(Value)
			local fovMap = {
				["100 FOV (150)"] = 150,
				["110 FOV (200)"] = 200,
				["120 FOV (250)"] = 250,
				["130 FOV (300)"] = 300,
				["140 FOV (350)"] = 350,
				["150 FOV (400)"] = 400,
			}

			local fovValue = fovMap[Value]
			if fovValue then
				FOVModule.SetFOV(fovValue)
			end
		end,
	})

	PlayerRight:AddLabel("Quick presets for common FOV values", true)

	-- ========================================================================== --
	--                            MOVEMENT TAB                                     --
	-- ========================================================================== --

	local MovementLeftBox = Tabs.Movement:AddLeftTabbox()
	local MovementRightBox = Tabs.Movement:AddRightTabbox()

	local MovementLeft = MovementLeftBox:AddTab("Basic")
	local MovementLeft2 = MovementLeftBox:AddTab("Adv Jump")
	local TrimpGroup = MovementRightBox:AddTab("Trimping")
	local MovementRight = MovementRightBox:AddTab("Slide")
	local MovementRight2 = MovementRightBox:AddTab("Mods")

	-- NOCLIP
	MovementLeft:AddToggle("Noclip", {
		Text = "Noclip",
		Tooltip = "Walk through walls and objects",
		Default = false,
	}):AddKeyPicker("NoclipKey", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Noclip" })

	Toggles.Noclip:OnChanged(function()
		if Toggles.Noclip.Value then
			NoclipModule.Start()
		else
			NoclipModule.Stop()
		end
	end)

	-- BUG EMOTE
	MovementLeft:AddToggle("BugEmote", {
		Text = "Bug Emote (Force Sit)",
		Tooltip = "Force your character to sit",
		Default = false,
	}):AddKeyPicker("BugEmoteKey", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Bug Emote" })

	Toggles.BugEmote:OnChanged(function()
		if Toggles.BugEmote.Value then
			BugEmoteModule.Start()
		else
			BugEmoteModule.Stop()
		end
	end)

	MovementLeft:AddDivider()

	-- FLY SYSTEM
	MovementLeft:AddToggle("FlyActivate", {
		Text = "Activate Fly",
		Tooltip = "Enable/disable flying mode (WASD + Space/Shift)",
		Default = false,
	}):AddKeyPicker("FlyKey", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Fly" })

	Toggles.FlyActivate:OnChanged(function()
		FlyModule.Toggle(Toggles.FlyActivate.Value)
	end)

	MovementLeft:AddInput("FlySpeed", {
		Default = "50",
		Numeric = true,
		Text = "Fly Speed",
		Tooltip = "Set flying speed (10-500)",
		Placeholder = "Enter speed",
		Callback = function(Value)
			local success = FlyModule.SetSpeed(Value)
			if not success then
				Error("Fly System", "Invalid speed value!", 1)
			end
		end,
	})

	MovementLeft:AddButton({
		Text = "Reset Fly",
		Tooltip = "Force stop fly if stuck",
		Func = function()
			FlyModule.Stop()
			Success("Fly System", "Fly has been reset", 2)
		end,
	})

	MovementLeft:AddLabel("Controls:\nWASD = Move\nSpace = Up\nShift = Down\nCamera = Direction", true)

	-- ========================================================================== --
	--                        NEW TRIMP SYSTEM UI SECTION                         --
	-- ========================================================================== --

	-- TOGGLE 1: AUTO BOUNCE (Fisika Pantulan)
	TrimpGroup:AddToggle("TrimpBounce", {
		Text = "Enable Auto Bounce",
		Tooltip = "Otomatis memantul saat jatuh mendekati tanah",
		Default = false,
	}):AddKeyPicker("KeyBounce", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Auto Bounce" })

	Toggles.TrimpBounce:OnChanged(function()
		EasyTrimpModule.ToggleBounce(Toggles.TrimpBounce.Value)
	end)

	-- TOGGLE 2: MOMENTUM SPEED (Kecepatan Udara)
	TrimpGroup:AddToggle("TrimpMomentum", {
		Text = "Enable Momentum Speed",
		Tooltip = "Menambah kecepatan otomatis saat berada di udara",
		Default = false,
	}):AddKeyPicker("KeyMomentum", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Air Momentum" })

	Toggles.TrimpMomentum:OnChanged(function()
		EasyTrimpModule.ToggleMomentum(Toggles.TrimpMomentum.Value)
	end)

	TrimpGroup:AddDivider()

	-- SLIDERS UNTUK BOUNCE (FITUR LAMA)
	TrimpGroup:AddSlider("BouncePower", {
		Text = "Bounce Power",
		Default = 100,
		Min = 50,
		Max = 300,
		Rounding = 0,
		Callback = function(v)
			EasyTrimpModule.SetPower(v)
		end,
	})

	TrimpGroup:AddSlider("GroundDistance", {
		Text = "Ground Check Distance",
		Default = 6,
		Min = 2,
		Max = 15,
		Rounding = 1,
		Callback = function(v)
			EasyTrimpModule.SetDist(v)
		end,
	})

	TrimpGroup:AddDivider()

	-- SLIDERS UNTUK MOMENTUM (FITUR BARU)
	TrimpGroup:AddSlider("MomentumBase", {
		Text = "Momentum Base Speed",
		Default = 50,
		Min = 10,
		Max = 150,
		Rounding = 0,
		Callback = function(v)
			EasyTrimpModule.SetBase(v)
		end,
	})

	TrimpGroup:AddSlider("MomentumMax", {
		Text = "Max Air Boost Speed",
		Default = 100,
		Min = 0,
		Max = 500,
		Rounding = 0,
		Callback = function(v)
			EasyTrimpModule.SetMax(v)
		end,
	})

	TrimpGroup:AddSlider("LandingLoss", {
		Text = "Landing Speed Loss",
		Default = 0,
		Min = 0,
		Max = 50,
		Rounding = 0,
		Callback = function(v)
			EasyTrimpModule.SetDrop(v)
		end,
	})

	-- AUTO JUMP TYPE
	MovementLeft2:AddDropdown("AutoJumpType", {
		Values = { "Bounce", "Realistic" },
		Default = "Bounce",
		Text = "Auto Jump Type",
		Tooltip = "Bounce = fast jump | Realistic = realistic jump",
		Callback = function(Value)
			AutoJumpModule.SetAutoJumpType(Value)
		end,
	})

	-- ROTATION 360°
	MovementLeft2:AddToggle("Rotation360", {
		Text = "Rotation 360°",
		Tooltip = "Rotate character 360° continuously (DO NOT use with emotes!)",
		Default = false,
	})

	Toggles.Rotation360:OnChanged(function()
		AutoJumpModule.ToggleRotation(Toggles.Rotation360.Value)
	end)

	-- BUNNY HOP TOGGLE
	MovementLeft2:AddToggle("BunnyHop", {
		Text = "Bunny Hop",
		Tooltip = "Auto jump continuously",
		Default = false,
	}):AddKeyPicker("BhopKey", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Bunny Hop" })

	Toggles.BunnyHop:OnChanged(function()
		if Toggles.BunnyHop.Value then
			AutoJumpModule.Start()
		else
			AutoJumpModule.Stop()
		end
	end)

	MovementLeft2:AddToggle("ShowMobileBhop", { Text = "Show Mobile Bhop Button", Default = false })
	Toggles.ShowMobileBhop:OnChanged(function()
		AutoJumpModule.SetMobileVisible(Toggles.ShowMobileBhop.Value)
	end)

	-- BHOP HOLD
	MovementLeft2:AddToggle("BhopHold", {
		Text = "Bhop Hold (Hold Space)",
		Tooltip = "Enable bhop only when holding Space",
		Default = false,
	})

	Toggles.BhopHold:OnChanged(function()
		AutoJumpModule.SetHoldEnabled(Toggles.BhopHold.Value)
	end)

	-- BHOP MODE
	MovementLeft2:AddDropdown("BhopMode", {
		Values = { "Acceleration", "No Acceleration" },
		Default = "Acceleration",
		Text = "Bhop Mode",
		Tooltip = "Acceleration = slide effect | No Acceleration = normal",
		Callback = function(Value)
			AutoJumpModule.SetBhopMode(Value)
		end,
	})

	-- BHOP ACCELERATION
	MovementLeft2:AddInput("BhopAccel", {
		Default = "-0.5",
		Numeric = true,
		Text = "Bhop Acceleration",
		Tooltip = "Negative value for slide effect (e.g., -0.5)",
		Placeholder = "-0.5",
		Callback = function(Value)
			AutoJumpModule.SetBhopAccel(Value)
		end,
	})

	-- JUMP COOLDOWN
	MovementLeft2:AddInput("JumpCooldown", {
		Default = "0.7",
		Numeric = true,
		Text = "Jump Cooldown (seconds)",
		Tooltip = "Delay between jumps",
		Placeholder = "0.7",
		Callback = function(Value)
			AutoJumpModule.SetJumpCooldown(Value)
		end,
	})

	-- INFINITE SLIDE
	MovementRight:AddToggle("InfiniteSlide", {
		Text = "Infinite Slide",
		Tooltip = "Slide infinitely (hold Shift while running)",
		Default = false,
	}):AddKeyPicker("SlideKey", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Infinite Slide" })

	Toggles.InfiniteSlide:OnChanged(function()
		if Toggles.InfiniteSlide.Value then
			InfiniteSlideModule.Start()
		else
			InfiniteSlideModule.Stop()
		end
	end)

	MovementRight:AddToggle("ShowMobileSlide", { Text = "Show Mobile Slide Button", Default = false })
	Toggles.ShowMobileSlide:OnChanged(function()
		InfiniteSlideModule.SetMobileVisible(Toggles.ShowMobileSlide.Value)
	end)

	MovementRight:AddInput("SlideSpeed", {
		Default = "-8",
		Numeric = true,
		Text = "Slide Speed",
		Tooltip = "Negative value = acceleration (e.g., -8)",
		Placeholder = "-8",
		Callback = function(Value)
			InfiniteSlideModule.SetSlideSpeed(Value)
		end,
	})

	MovementRight:AddLabel("How to use:\n• Slide will infinitely\n• Adjust speed for acceleration", true)

	-- BOUNCE MODIFICATION
	MovementRight2:AddToggle("BounceModify", {
		Text = "Modify Bounce",
		Tooltip = "Modify player bounce speed",
		Default = false,
	})

	Toggles.BounceModify:OnChanged(function()
		if Toggles.BounceModify.Value then
			BounceModule.Start()
		else
			BounceModule.Stop()
		end
	end)

	MovementRight2:AddInput("BounceSpeed", {
		Default = "110",
		Numeric = true,
		Text = "Bounce Speed",
		Tooltip = "Player bounce walk speed (0-1000)",
		Placeholder = "110",
		Callback = function(Value)
			BounceModule.SetSpeed(Value)
		end,
	})

	MovementRight2:AddDivider()

	-- GRAVITY SYSTEM
	MovementRight2:AddToggle("Gravity", {
		Text = "Gravity",
		Tooltip = "Modify workspace gravity",
		Default = false,
	}):AddKeyPicker("GravityKey", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Gravity" })

	Toggles.Gravity:OnChanged(function()
		if Toggles.Gravity.Value then
			GravityModule.Start()
		else
			GravityModule.Stop()
		end
	end)

	MovementRight2:AddInput("GravityValue", {
		Default = "10",
		Numeric = true,
		Text = "Gravity Value",
		Tooltip = "Lower = slower fall (1-200)",
		Placeholder = "10",
		Callback = function(Value)
			GravityModule.SetGravity(Value)
		end,
	})

	MovementRight2:AddLabel(
		"💡 Lower gravity = slower fall\nDefault gravity: " .. GravityModule.GetOriginalGravity(),
		true
	)

	MovementRight2:AddDivider()

	MovementRight2:AddToggle("GrappleGlitch", {
		Text = "Grapple Glitch",
		Tooltip = "Tahan V lalu Klik Kiri untuk melontarkan karaktermu ke arah kamera/mouse!",
		Default = false,
	}):AddKeyPicker(
		"GrappleGlitchKey",
		{ Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Super Launch" }
	)

	Toggles.GrappleGlitch:OnChanged(function()
		if Toggles.GrappleGlitch.Value then
			GrappleGlitchModule.Start()
		else
			GrappleGlitchModule.Stop()
		end
	end)

	MovementRight2:AddToggle("ShowMobileGlitch", { Text = "Show Mobile Launch Button", Default = false })
	Toggles.ShowMobileGlitch:OnChanged(function()
		GrappleGlitchModule.SetMobileVisible(Toggles.ShowMobileGlitch.Value)
	end)

	-- SLIDER & INPUT UNTUK TINGGI
	MovementRight2:AddSlider("LaunchHeightSlider", {
		Text = "Tinggi Loncatan",
		Tooltip = "Atur tinggi lontaran dengan bebas (0 - 5000)",
		Default = 150,
		Min = 0,
		Max = 5000,
		Rounding = 0,
		Compact = false,
		Callback = function(Value)
			GrappleGlitchModule.SetHeight(Value)
			-- Sinkronkan angka ke Input Box
			if Options.LaunchHeightInput then
				Options.LaunchHeightInput:SetValue(tostring(Value))
			end
		end,
	})

	MovementRight2:AddInput("LaunchHeightInput", {
		Default = "150",
		Numeric = true,
		Finished = true,
		Text = "Input Manual Tinggi",
		Tooltip = "Ketik angka tinggi (0 - 5000) lalu tekan Enter",
		Placeholder = "150",
		Callback = function(Value)
			local num = tonumber(Value)
			if num then
				-- Sinkronkan angka ke Slider
				if Options.LaunchHeightSlider then
					Options.LaunchHeightSlider:SetValue(num)
				end
				GrappleGlitchModule.SetHeight(num)
			end
		end,
	})

	MovementRight2:AddDivider()

	-- SLIDER & INPUT UNTUK KECEPATAN/JARAK
	MovementRight2:AddSlider("LaunchDistanceSlider", {
		Text = "Kecepatan / Jarak",
		Tooltip = "Atur kecepatan lompatan dengan bebas (0 - 10000)",
		Default = 200,
		Min = 0,
		Max = 10000,
		Rounding = 0,
		Compact = false,
		Callback = function(Value)
			GrappleGlitchModule.SetDistance(Value)
			-- Sinkronkan angka ke Input Box
			if Options.LaunchDistanceInput then
				Options.LaunchDistanceInput:SetValue(tostring(Value))
			end
		end,
	})

	MovementRight2:AddInput("LaunchDistanceInput", {
		Default = "200",
		Numeric = true,
		Finished = true,
		Text = "Input Manual Jarak",
		Tooltip = "Ketik angka jarak (0 - 10000) lalu tekan Enter",
		Placeholder = "200",
		Callback = function(Value)
			local num = tonumber(Value)
			if num then
				-- Sinkronkan angka ke Slider
				if Options.LaunchDistanceSlider then
					Options.LaunchDistanceSlider:SetValue(num)
				end
				GrappleGlitchModule.SetDistance(num)
			end
		end,
	})

	MovementRight2:AddDivider()

	MovementRight2:AddDropdown("LaunchDirection", {
		Values = {
			"Maju (Ke Depan)",
			"Mundur (Ke Belakang)",
			"Kiri (Ke Kiri)",
			"Kanan (Ke Kanan)",
			"Tetap (Lurus Ke Atas)",
			"Ke Arah Kursor (Mouse)",
		},
		Default = "Maju (Ke Depan)",
		Text = "Arah Terbang",
		Tooltip = "Pilih arah karakter saat dilontarkan",
		Callback = function(Value)
			if Value == "Maju (Ke Depan)" then
				GrappleGlitchModule.SetDirection("Maju")
			elseif Value == "Mundur (Ke Belakang)" then
				GrappleGlitchModule.SetDirection("Mundur")
			elseif Value == "Kiri (Ke Kiri)" then
				GrappleGlitchModule.SetDirection("Kiri")
			elseif Value == "Kanan (Ke Kanan)" then
				GrappleGlitchModule.SetDirection("Kanan")
			elseif Value == "Tetap (Lurus Ke Atas)" then
				GrappleGlitchModule.SetDirection("Tetap")
			elseif Value == "Ke Arah Kursor (Mouse)" then
				GrappleGlitchModule.SetDirection("Mouse")
			end
			Success("Super Launch", "Arah diubah ke: " .. Value, 1)
		end,
	})

	MovementRight2:AddLabel(
		"💡 Cara Pakai:\n1. Aktifkan toggle di atas\n2. Tahan tombol V\n3. Arahkan kameramu (atau Mouse)\n4. Klik Kiri untuk melesat!",
		true
	)

	-- [PASTE KODE UI DI SINI]

	MovementRight2:AddDivider()

	MovementRight2:AddToggle("GrappleClipEnable", {
		Text = "Enable GrappleEmote",
		Tooltip = "Gabungan Emote + Grapple + Auto Dorong untuk 100% tembus",
		Default = false,
	})

	Toggles.GrappleClipEnable:OnChanged(function()
		GrappleClipModule.SetEnabled(Toggles.GrappleClipEnable.Value)
	end)

	MovementRight2:AddToggle("ShowMobileOOB", { Text = "Show Mobile Clip Button", Default = false })
	Toggles.ShowMobileOOB:OnChanged(function()
		GrappleClipModule.SetMobileVisible(Toggles.ShowMobileOOB.Value)
	end)

	MovementRight2:AddLabel("Keybind Eksekusi"):AddKeyPicker("GrappleClipKey", {
		Default = "X",
		SyncToggleState = false,
		Mode = "Press",
		Text = "Trigger Ultimate Clip",
		Callback = function()
			GrappleClipModule.Execute()
		end,
	})

	MovementRight2:AddDropdown("GrappleClipSlot", {
		Values = { "Slot 1", "Slot 2", "Slot 3", "Slot 4", "Slot 5", "Slot 6" },
		Default = "Slot 1",
		Multi = false,
		Text = "Pilih Slot Emote",
		Callback = function(Value)
			GrappleClipModule.SetSlot(Value)
		end,
	})

	MovementRight2:AddSlider("GrappleClipDelay", {
		Text = "Jeda Emote (Detik)",
		Tooltip = "Waktu sebelum didorong & ditembak (Default: 0.05)",
		Default = 0.05,
		Min = 0.01,
		Max = 0.20,
		Rounding = 2,
		Compact = false,
		Callback = function(Value)
			GrappleClipModule.SetDelay(Value)
		end,
	})

	MovementRight2:AddSlider("GrappleClipBoost", {
		Text = "Jarak Auto Dorong (Studs)",
		Tooltip = "Berapa tebal dorongan untuk menembus kaca/tembok. Isi 0 jika ingin murni Grapple aja.",
		Default = 3,
		Min = 0,
		Max = 15,
		Rounding = 1,
		Compact = false,
		Callback = function(Value)
			GrappleClipModule.SetCFrameBoost(Value)
		end,
	})

	MovementRight2:AddLabel(
		"💡 Setup Terbaik:\n• Set Jeda ke 0.05\n• Set Auto Dorong ke 3 atau 4\n• Tempelkan muka ke kaca, lalu tekan X!",
		true
	)

	-- ========================================================================== --
	--                            VISUAL TAB                                       --
	-- ========================================================================== --

	local VisualLeftBox = Tabs.Visual:AddLeftTabbox()
	local VisualRightBox = Tabs.Visual:AddRightTabbox()

	local VisualLeft = VisualLeftBox:AddTab("Barriers")
	local VisualLeft2 = VisualLeftBox:AddTab("Lighting")
	local VisualRight = VisualRightBox:AddTab("Camera & Effects")
	local VisualRight2 = VisualRightBox:AddTab("Optimization")

	-- ==================== BARRIERS ====================
	VisualLeft:AddToggle("RemoveBarriers", {
		Text = "Remove Barriers",
		Tooltip = "Disable collision on invisible barriers",
		Default = false,
	}):AddKeyPicker(
		"RemoveBarriersKey",
		{ Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Remove Barriers" }
	)

	Toggles.RemoveBarriers:OnChanged(function()
		if Toggles.RemoveBarriers.Value then
			RemoveBarriersModule.Start()
		else
			RemoveBarriersModule.Stop()
		end
	end)

	VisualLeft:AddToggle("ShowMobileRBarriers", { Text = "Show Mobile R-Barriers", Default = false })
	Toggles.ShowMobileRBarriers:OnChanged(function()
		RemoveBarriersModule.SetMobileVisible(Toggles.ShowMobileRBarriers.Value)
	end)

	VisualLeft:AddDivider()

	VisualLeft:AddToggle("BarriersVisible", {
		Text = "Barriers Visible",
		Tooltip = "Make invisible barriers visible with color",
		Default = false,
	}):AddKeyPicker(
		"BarriersVisibleKey",
		{ Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Barriers Visible" }
	)

	Toggles.BarriersVisible:OnChanged(function()
		if Toggles.BarriersVisible.Value then
			BarriersVisibleModule.Start()
		else
			BarriersVisibleModule.Stop()
		end
	end)

	VisualLeft:AddToggle("ShowMobileVBarriers", { Text = "Show Mobile V-Barriers", Default = false })
	Toggles.ShowMobileVBarriers:OnChanged(function()
		BarriersVisibleModule.SetMobileVisible(Toggles.ShowMobileVBarriers.Value)
	end)

	VisualLeft:AddDropdown("BarriersColor", {
		Values = { "Merah", "Biru", "Hijau", "Kuning", "Ungu", "Pink", "Cyan", "Oranye", "Putih", "Hitam" },
		Default = "Merah",
		Text = "Barriers Color",
		Tooltip = "Choose color for barriers",
		Callback = function(Value)
			local colors = {
				Merah = Color3.fromRGB(255, 0, 0),
				Biru = Color3.fromRGB(0, 100, 255),
				Hijau = Color3.fromRGB(0, 255, 0),
				Kuning = Color3.fromRGB(255, 255, 0),
				Ungu = Color3.fromRGB(150, 0, 255),
				Pink = Color3.fromRGB(255, 0, 255),
				Cyan = Color3.fromRGB(0, 255, 255),
				Oranye = Color3.fromRGB(255, 128, 0),
				Putih = Color3.fromRGB(255, 255, 255),
				Hitam = Color3.fromRGB(0, 0, 0),
			}
			BarriersVisibleModule.SetColor(colors[Value] or Color3.fromRGB(255, 0, 0))
			Success("Color Changed", "Barriers color: " .. Value, 1)
		end,
	})

	VisualLeft:AddSlider("BarriersTransparency", {
		Text = "Transparency",
		Tooltip = "Adjust barriers transparency (0 = solid, 100 = invisible)",
		Default = 0,
		Min = 0,
		Max = 100,
		Rounding = 0,
		Compact = false,
		Suffix = "%",
		Callback = function(Value)
			local transparencyValue = Value / 100
			BarriersVisibleModule.SetTransparencyLevel(transparencyValue)

			-- Sync ke input box (kalau slider diubah, input ikut update)
			if Options.BarriersTransparencyInput then
				Options.BarriersTransparencyInput:SetValue(tostring(Value))
			end
		end,
	})

	VisualLeft:AddInput("BarriersTransparencyInput", {
		Default = "0",
		Numeric = true,
		Text = "Transparency Value",
		Tooltip = "Enter transparency value (0-100)",
		Placeholder = "0-100",
		Callback = function(Value)
			local num = tonumber(Value)
			if num and num >= 0 and num <= 100 then
				-- Update slider
				if Options.BarriersTransparency then
					Options.BarriersTransparency:SetValue(num)
				end
				-- Apply transparency
				local transparencyValue = num / 100
				BarriersVisibleModule.SetTransparencyLevel(transparencyValue)
			else
				Error("Transparency", "Value must be between 0-100", 2)
			end
		end,
	})

	-- ==================== LIGHTING ====================
	VisualLeft2:AddToggle("FullBright", {
		Text = "Full Bright",
		Tooltip = "Maximize game lighting",
		Default = false,
	}):AddKeyPicker("FullBrightKey", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Full Bright" })

	Toggles.FullBright:OnChanged(function()
		VisualFeaturesModule.ToggleFullBright(Toggles.FullBright.Value)
	end)

	VisualLeft2:AddToggle("RemoveFog", {
		Text = "Remove Fog",
		Tooltip = "Remove fog/atmosphere effects",
		Default = false,
	}):AddKeyPicker("RemoveFogKey", { Default = "", SyncToggleState = true, Mode = "Toggle", Text = "Remove Fog" })

	Toggles.RemoveFog:OnChanged(function()
		VisualFeaturesModule.ToggleRemoveFog(Toggles.RemoveFog.Value)
	end)

	VisualLeft2:AddLabel("💡 Full Bright = Maximum brightness\nRemove Fog = Clear visibility", true)

	-- ==================== CAMERA & EFFECTS ====================
	VisualRight:AddToggle("CameraStretch", {
		Text = "Camera Stretch",
		Tooltip = "Stretch camera view",
		Default = false,
	})

	Toggles.CameraStretch:OnChanged(function()
		VisualFeaturesModule.ToggleCameraStretch(Toggles.CameraStretch.Value)
	end)

	VisualRight:AddInput("StretchH", {
		Default = "0.8",
		Numeric = true,
		Text = "Stretch Horizontal",
		Tooltip = "Horizontal stretch value (0.1 - 2.0)",
		Placeholder = "0.8",
		Callback = function(Value)
			VisualFeaturesModule.SetStretchH(Value)
		end,
	})

	VisualRight:AddInput("StretchV", {
		Default = "0.8",
		Numeric = true,
		Text = "Stretch Vertical",
		Tooltip = "Vertical stretch value (0.1 - 2.0)",
		Placeholder = "0.8",
		Callback = function(Value)
			VisualFeaturesModule.SetStretchV(Value)
		end,
	})

	VisualRight:AddDivider()

	-- ==================== FPS & TIMER DISPLAY ====================
	VisualRight:AddToggle("FPSTimerDisplay", {
		Text = "FPS & Timer Display",
		Tooltip = "Show FPS counter and game timer (top-right corner)",
		Default = false,
	})

	Toggles.FPSTimerDisplay:OnChanged(function()
		if Toggles.FPSTimerDisplay.Value then
			FPSTimerDisplayModule.Start()
		else
			FPSTimerDisplayModule.Stop()
		end
	end)

	VisualRight:AddLabel("💡 Shows FPS and game round timer\nDisplayed in top-right corner of screen", true)

	VisualRight:AddDivider()

	-- FAKE STREAK
	VisualRight:AddInput("FakeStreak", {
		Default = "",
		Numeric = true,
		Text = "Fake Streak",
		Tooltip = "Fake your streak value (visual only)",
		Placeholder = "Enter streak number",
		Callback = function(Value)
			VisualFeaturesModule.SetFakeStreak(Value)
		end,
	})

	VisualRight:AddButton({
		Text = "Reset Streak",
		Tooltip = "Remove fake streak and return to normal",
		Func = function()
			VisualFeaturesModule.ResetStreak()
		end,
	})

	VisualRight:AddLabel("⚠️ Fake streak is visual only\nDoes not affect actual gameplay", true)

	-- ==================== OPTIMIZATION ====================
	VisualRight2:AddButton({
		Text = "Anti Lag 1 - Light",
		Tooltip = "Light optimization (shadows, fog, materials)",
		Func = function()
			VisualFeaturesModule.AntiLag1()
		end,
	})

	VisualRight2:AddButton({
		Text = "Anti Lag 2 - Aggressive",
		Tooltip = "Aggressive optimization (textures, effects, particles)",
		Func = function()
			VisualFeaturesModule.AntiLag2()
		end,
	})

	VisualRight2:AddButton({
		Text = "Anti Lag 3 - Textures",
		Tooltip = "Focus on removing textures and decals",
		Func = function()
			VisualFeaturesModule.AntiLag3()
		end,
	})

	VisualRight2:AddLabel(
		"💡 Anti Lag Info:\n• Level 1 = Light (safe)\n• Level 2 = Aggressive (max FPS)\n• Level 3 = Textures only",
		true
	)

	VisualRight2:AddLabel("⚠️ Warning:\nAnti Lag cannot be undone!\nYou must rejoin to restore visuals", true)

	-- ========================================================================== --
	--                            SERVER TAB                                       --
	-- ========================================================================== --

	local ServerLeftBox = Tabs.Server:AddLeftTabbox()
	local ServerRightBox = Tabs.Server:AddRightTabbox()

	local ServerLeft = ServerLeftBox:AddTab("Info")
	local ServerLeft2 = ServerLeftBox:AddTab("Quick Actions")
	local ServerRight = ServerRightBox:AddTab("Join Modes")
	local ServerRight2 = ServerRightBox:AddTab("Misc")

	-- SERVER INFO
	local gameModeName = "Loading..."
	local gameModeLabel = ServerLeft:AddLabel("Game Mode: " .. gameModeName, false)

	task.spawn(function()
		local success, productInfo = pcall(function()
			return MarketplaceService:GetProductInfo(placeId)
		end)
		if success and productInfo then
			local fullName = productInfo.Name
			if fullName:find("Evade %- ") then
				gameModeName = fullName:match("Evade %- (.+)") or fullName
			else
				gameModeName = fullName
			end
			if gameModeLabel and gameModeLabel.SetText then
				pcall(function()
					gameModeLabel:SetText("Game Mode: " .. gameModeName)
				end)
			end
		else
			gameModeName = "Unknown"
			if gameModeLabel and gameModeLabel.SetText then
				pcall(function()
					gameModeLabel:SetText("Game Mode: " .. gameModeName)
				end)
			end
		end
	end)

	ServerLeft:AddLabel("Current Players: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers, false)
	ServerLeft:AddLabel("Server ID: " .. jobId, true)
	ServerLeft:AddLabel("Place ID: " .. tostring(placeId), false)

	ServerLeft:AddButton({
		Text = "Copy Server Link",
		Tooltip = "Copy the current server's join link",
		Func = function()
			local serverLink = ServerUtils.GetServerLink()
			local success, errorMsg = pcall(function()
				setclipboard(serverLink)
			end)

			if success then
				Info("Link Copied", "Server invite link copied to clipboard!", 3)
			else
				Error("Copy Failed", "Your executor doesn't support setclipboard", 3)
				warn("Failed to copy link:", errorMsg)
			end
		end,
	})

	-- QUICK ACTIONS
	ServerLeft2:AddButton({
		Text = "Rejoin Server",
		Tooltip = "Rejoin the current server",
		Func = function()
			pcall(function()
				TeleportService:Teleport(game.PlaceId, player)
			end)
		end,
	})

	ServerLeft2:AddButton({
		Text = "Server Hop",
		Tooltip = "Join a random server with 5+ players",
		Func = function()
			local success = ServerUtils.ServerHop(5)
			if not success then
				Library:Notify({
					Title = "Server Hop Failed",
					Description = "No servers with 5+ players found!",
					Time = 3,
				})
			end
		end,
	})

	ServerLeft2:AddButton({
		Text = "Hop to Small Server",
		Tooltip = "Hop to the emptiest available server",
		Func = function()
			local success = ServerUtils.HopToSmallestServer()
			if not success then
				Library:Notify({
					Title = "Server Hop Failed",
					Description = "Could not fetch servers!",
					Time = 3,
				})
			end
		end,
	})

	-- JOIN MODES
	ServerRight:AddButton({
		Text = "Join Big Team",
		Tooltip = "Join the most populated Big Team server",
		Func = function()
			ServerUtils.JoinServerByPlaceId(10324346056, "Big Team")
		end,
	})

	ServerRight:AddButton({
		Text = "Join Casual",
		Tooltip = "Join the most populated Casual server",
		Func = function()
			ServerUtils.JoinServerByPlaceId(10662542523, "Casual")
		end,
	})

	ServerRight:AddButton({
		Text = "Join Social Space",
		Tooltip = "Join the most populated Social Space server",
		Func = function()
			ServerUtils.JoinServerByPlaceId(10324347967, "Social Space")
		end,
	})

	ServerRight:AddButton({
		Text = "Join Player Nextbots",
		Tooltip = "Join the most populated Player Nextbots server",
		Func = function()
			ServerUtils.JoinServerByPlaceId(121271605799901, "Player Nextbots")
		end,
	})

	ServerRight:AddButton({
		Text = "Join VC Only",
		Tooltip = "Join the most populated VC Only server",
		Func = function()
			ServerUtils.JoinServerByPlaceId(10808838353, "VC Only")
		end,
	})

	ServerRight:AddButton({
		Text = "Join Pro",
		Tooltip = "Join the most populated Pro server",
		Func = function()
			ServerUtils.JoinServerByPlaceId(11353528705, "Pro")
		end,
	})

	ServerRight:AddButton({
		Text = "Join Pro (Low Players)",
		Tooltip = "Join the emptiest Pro server",
		Func = function()
			ServerUtils.JoinLowestServer(11353528705, "Pro Low")
		end,
	})

	ServerRight:AddDivider()

	local customServerCode = ""

	ServerRight:AddInput("CustomServerCode", {
		Default = "",
		Numeric = false,
		Finished = false,
		Text = "Custom Server Code",
		Tooltip = "Enter custom server passcode",
		Placeholder = "Enter custom server passcode",
		Callback = function(Value)
			customServerCode = Value
		end,
	})

	ServerRight:AddButton({
		Text = "Join Custom Server",
		Tooltip = "Join custom server with the code above",
		Func = function()
			if customServerCode == "" then
				Library:Notify({
					Title = "Join Failed",
					Description = "Please enter a custom server code!",
					Time = 3,
				})
				return
			end

			local success, result = pcall(function()
				return game:GetService("ReplicatedStorage")
					:WaitForChild("Events")
					:WaitForChild("CustomServers")
					:WaitForChild("JoinPasscode")
					:InvokeServer(customServerCode)
			end)

			if success then
				Library:Notify({
					Title = "Joining Custom Server",
					Description = "Attempting to join with code: " .. customServerCode,
					Time = 3,
				})
			else
				Library:Notify({
					Title = "Join Failed",
					Description = "Invalid code or server unavailable!",
					Time = 3,
				})
			end
		end,
	})

	-- ==================== LAG SWITCH (FIXED) ====================
	ServerRight2:AddToggle("LagSwitchEnable", {
		Text = "Enable Lag Switch",
		Tooltip = "Aktifkan sistem lag (Setelah ON, pencet Keybind untuk lag)",
		Default = false,
	})

	Toggles.LagSwitchEnable:OnChanged(function()
		LagSwitchModule.SetEnabled(Toggles.LagSwitchEnable.Value)
	end)

	-- SEKARANG KEYPICKER MENGGUNAKAN MODE "PRESS" UNTUK TRIGGER
	ServerRight2:AddLabel("Trigger Lag Keybind"):AddKeyPicker("LagTriggerKey", {
		Default = "Z",
		SyncToggleState = false,
		Mode = "Press",
		Text = "Trigger Lag Burst",
		Callback = function()
			LagSwitchModule.Execute()
		end,
	})

	ServerRight2:AddDropdown("LagSwitchMode", {
		Values = { "Normal", "Demon" },
		Default = "Normal",
		Text = "Lag Switch Mode",
		Callback = function(Value)
			LagSwitchModule.SetMode(Value)
		end,
	})

	ServerRight2:AddInput("LagDelay", {
		Default = "0.1",
		Numeric = true,
		Text = "Lag Delay (seconds)",
		Callback = function(Value)
			LagSwitchModule.SetDelay(Value)
		end,
	})

	ServerRight2:AddInput("LagIntensity", {
		Default = "1000000",
		Numeric = true,
		Text = "Lag Intensity",
		Callback = function(Value)
			LagSwitchModule.SetIntensity(Value)
		end,
	})

	ServerRight2:AddDivider()

	ServerRight2:AddInput("DemonHeight", {
		Default = "10",
		Numeric = true,
		Text = "Demon Rise Height",
		Callback = function(Value)
			LagSwitchModule.SetDemonHeight(Value)
		end,
	})

	ServerRight2:AddInput("DemonSpeed", {
		Default = "80",
		Numeric = true,
		Text = "Demon Rise Speed",
		Callback = function(Value)
			LagSwitchModule.SetDemonSpeed(Value)
		end,
	})

	ServerRight2:AddLabel("Normal: Pencet keybind untuk lag.", true)
	ServerRight2:AddLabel("Demon: Lag + meluncur ke atas.", true)

	ServerRight2:AddDivider()

	ServerRight2:AddToggle("UnlockLeaderboard", {
		Text = "Unlock Leaderboard UI",
		Tooltip = "Buat custom button untuk Zoom, Front View, dan Leaderboard",
		Default = false,
	})

	Toggles.UnlockLeaderboard:OnChanged(function()
		if Toggles.UnlockLeaderboard.Value then
			UnlockLeaderboardModule.Create()
		else
			UnlockLeaderboardModule.Destroy()
		end
	end)

	ServerRight2:AddButton({
		Text = "Remove Leaderboard UI",
		Tooltip = "Hapus custom button dan kembalikan topbar normal",
		Func = function()
			UnlockLeaderboardModule.Destroy()
		end,
	})

	-- ========================================================================== --
	--                            SHOP / AUTO BUY TAB                             --
	-- ========================================================================== --

	local ShopLeftBox = Tabs.AutoBuy:AddLeftTabbox()
	local ShopRightBox = Tabs.AutoBuy:AddRightTabbox()

	local ShopLeft = ShopLeftBox:AddTab("Manual Buy")
	local ShopRight = ShopRightBox:AddTab("Auto Buy")

	local selectedManualItem = ""
	local shopCategories = AutoBuyModule.GetCategories()

	-- ===== MANUAL BUY SECTION =====
	ShopLeft:AddDropdown("ManualCategorySelect", {
		Values = shopCategories,
		Default = 1,
		Multi = false,
		Text = "Kategori",
		Tooltip = "Pilih kategori item (Loadout, Emotes, dll)",
		Callback = function(Value)
			-- Saat kategori berubah, update dropdown item di bawahnya
			local itemsInCategory = AutoBuyModule.GetItems(Value)
			if Options.ManualItemSelect then
				Options.ManualItemSelect:SetValues(itemsInCategory)
				Options.ManualItemSelect:SetValue(itemsInCategory[1])
			end
		end,
	})

	ShopLeft:AddDropdown("ManualItemSelect", {
		Values = { "Pilih Kategori Dulu" },
		Default = 1,
		Multi = false,
		Text = "Pilih Item",
		Searchable = true, -- Tetap bisa diketik
		Tooltip = "Pilih item yang ingin dibeli",
		Callback = function(Value)
			selectedManualItem = Value
		end,
	})

	ShopLeft:AddButton({
		Text = "Beli 1x",
		Func = function()
			AutoBuyModule.Purchase(selectedManualItem, 1)
		end,
	})

	ShopLeft:AddButton({
		Text = "Beli 5x",
		Func = function()
			AutoBuyModule.Purchase(selectedManualItem, 5)
		end,
	})

	ShopLeft:AddButton({
		Text = "Beli 10x",
		Func = function()
			AutoBuyModule.Purchase(selectedManualItem, 10)
		end,
	})

	ShopLeft:AddDivider()

	ShopLeft:AddButton({
		Text = "Cetak Semua Data ke Console (F9)",
		Func = function()
			AutoBuyModule.PrintScannedItems()
		end,
	})

	-- ===== AUTO BUY SECTION =====
	ShopRight:AddDropdown("AutoCategorySelect", {
		Values = shopCategories,
		Default = 1,
		Multi = false,
		Text = "Kategori Auto",
		Callback = function(Value)
			local itemsInCategory = AutoBuyModule.GetItems(Value)
			if Options.AutoItemSelect then
				Options.AutoItemSelect:SetValues(itemsInCategory)
				Options.AutoItemSelect:SetValue(itemsInCategory[1])
			end
		end,
	})

	ShopRight:AddDropdown("AutoItemSelect", {
		Values = { "Pilih Kategori Dulu" },
		Default = 1,
		Multi = false,
		Text = "Target Auto Buy",
		Searchable = true,
		Callback = function(Value)
			AutoBuyModule.SetItem(Value)
		end,
	})

	ShopRight:AddInput("AutoBuyDelay", {
		Default = "5",
		Numeric = true,
		Finished = true,
		Text = "Delay Auto Buy (Detik)",
		Placeholder = "5",
		Callback = function(Value)
			local num = tonumber(Value)
			if num and num > 0 then
				AutoBuyModule.SetDelay(num)
			end
		end,
	})

	ShopRight:AddToggle("EnableAutoBuy", {
		Text = "Enable Auto Buy",
		Default = false,
	})

	Toggles.EnableAutoBuy:OnChanged(function()
		if Toggles.EnableAutoBuy.Value then
			AutoBuyModule.Start()
		else
			AutoBuyModule.Stop()
		end
	end)

	ShopRight:AddDivider()
	ShopRight:AddLabel("⚠️ Pastikan uangmu cukup untuk Auto Buy berkelanjutan.", true)

	-- Pancing update UI pertama kali setelah UI ter-render
	task.spawn(function()
		task.wait(0.5)
		if shopCategories[1] and Options.ManualCategorySelect then
			Options.ManualCategorySelect:SetValue(shopCategories[1])
			Options.AutoCategorySelect:SetValue(shopCategories[1])
		end
	end)

	-- ========================================================================== --
	--                            UI SETTINGS TAB                                  --
	-- ========================================================================== --

	local UISettingsLeftBox = Tabs["UI Settings"]:AddLeftTabbox()
	local MenuGroup = UISettingsLeftBox:AddTab("Menu")

	MenuGroup:AddToggle("KeybindMenuOpen", {
		Default = Library.KeybindFrame.Visible,
		Text = "Open Keybind Menu",
		Callback = function(value)
			Library.KeybindFrame.Visible = value
		end,
	})

	MenuGroup:AddToggle("AutoSaveToggle", {
		Text = "Auto Save Config",
		Default = false,
		Tooltip = "Otomatis menyimpan config setiap 5 detik",
	})

	-- LOGIKA TETAP SAMA (Boleh ditaruh di bawah MenuGroup atau di mana saja)
	task.spawn(function()
		while true do
			task.wait(5)
			if Toggles.AutoSaveToggle and Toggles.AutoSaveToggle.Value then
				if SaveManager.CurrentConfig and SaveManager.CurrentConfig ~= "" then
					pcall(function()
						SaveManager:Save(SaveManager.CurrentConfig)
					end)
				end
			end
		end
	end)

	MenuGroup:AddToggle("EnableNotifications", {
		Default = true,
		Text = "Enable Notifications",
		Tooltip = "Toggle all script notifications on/off",
		Callback = function(value)
			notificationsEnabled = value
			if value then
				Library:Notify({
					Title = "🔔 Notifications",
					Description = "Notifications enabled",
					Time = 2,
				})
			else
				-- No notification when disabled (obviously)
			end
		end,
	})

	MenuGroup:AddToggle("ShowArrayList", {
		Default = false,
		Text = "Show Array List",
		Tooltip = "Menampilkan daftar fitur yang sedang aktif di pojok kanan atas",
		Callback = function(value)
			if value then
				ArrayListModule.Start()
				Success("Array List", "Ditampilkan", 2)
			else
				ArrayListModule.Stop()
			end
		end,
	})

	MenuGroup:AddToggle("ShowCustomCursor", {
		Text = "Custom Cursor",
		Default = true,
		Callback = function(Value)
			Library.ShowCustomCursor = Value
		end,
	})

	MenuGroup:AddDropdown("NotificationSide", {
		Values = { "Left", "Right" },
		Default = "Right",
		Text = "Notification Side",
		Callback = function(Value)
			Library:SetNotifySide(Value)
		end,
	})

	MenuGroup:AddDropdown("DPIDropdown", {
		Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
		Default = "100%",
		Text = "DPI Scale",
		Callback = function(Value)
			Value = Value:gsub("%%", "")
			local DPI = tonumber(Value)
			Library:SetDPIScale(DPI)
		end,
	})

	MenuGroup:AddDivider()

	MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
		Default = "RightShift",
		NoUI = true,
		Text = "Menu keybind",
	})

	MenuGroup:AddButton("Unload", function()
		Library:Unload()
	end)

	Library.ToggleKeybind = Options.MenuKeybind

	-- ========================================================================== --
	--                            THEME & SAVE MANAGER                            --
	-- ========================================================================== --

	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)

	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

	ThemeManager:SetFolder("rzprivate")
	SaveManager:SetFolder("rzprivate/evade")

	SaveManager:BuildConfigSection(Tabs["UI Settings"])
	ThemeManager:ApplyToTab(Tabs["UI Settings"])

	SaveManager:LoadAutoloadConfig()

	-- ========================================================================== --
	--                            FINAL SETUP & LOAD                              --
	-- ========================================================================== --

	-- Initialize Emote Hook
	EmoteChangerModule.Init()
	task.delay(2, function()
		isScriptLoading = false
		Library:Notify({
			Title = "rzprivate - Evade",
			Description = "Script loaded successfully! All features ready.",
			Time = 5,
		})
	end)

	Library:OnUnload(function()
		print("rzprivate - Evade unloaded!")

		-- === CLEANUP FLOATING BUTTONS (MOBILE) ===
		local core = pcall(function()
			return gethui()
		end) and gethui() or game:GetService("CoreGui")
		local guiNames = {
			"BhopMobileBtn",
			"SlideMobileBtn",
			"GlitchMobileBtn",
			"ClipMobileBtn",
			"TPMobileBtn",
			"TPFarBtn",
			"TPSkyBtn",
			"PlaceFarBtn",
			"PlaceSkyBtn",
			"RBarriersMobileBtn",
			"VBarriersMobileBtn",
		}
		for _, name in ipairs(guiNames) do
			local gui = core:FindFirstChild(name)
			if gui then
				pcall(function()
					gui:Destroy()
				end)
			end
		end

		-- === MODUL BARU (DRACONIC INTEGRATED) ===
		if AntiNextbotModule then
			AntiNextbotModule.Stop()
		end
		if UnifiedAutoFarm then
			UnifiedAutoFarm.SetMode("None")
		end
		if AntiAFKModule then
			AntiAFKModule.Stop()
		end

		-- === MODUL COMBAT ===
		if AutoSelfReviveModule and AutoSelfReviveModule.IsEnabled() then
			AutoSelfReviveModule.Stop()
		end
		if InstantReviveModule and InstantReviveModule.IsEnabled() then
			InstantReviveModule.Stop()
		end
		if AutoWhistleModule and AutoWhistleModule.IsEnabled() then
			AutoWhistleModule.Stop()
		end

		-- === MODUL MOVEMENT ===
		if NoclipModule and NoclipModule.IsEnabled() then
			NoclipModule.Stop()
		end
		if BugEmoteModule and BugEmoteModule.IsEnabled() then
			BugEmoteModule.Stop()
		end
		if FlyModule and FlyModule.IsFlying() then
			FlyModule.Stop()
		end
		if AutoJumpModule and AutoJumpModule.IsEnabled() then
			AutoJumpModule.Stop()
		end
		if InfiniteSlideModule and InfiniteSlideModule.IsEnabled() then
			InfiniteSlideModule.Stop()
		end
		if BounceModule and BounceModule.IsEnabled() then
			BounceModule.Stop()
		end
		if GravityModule and GravityModule.IsEnabled() then
			GravityModule.Stop()
		end
		if GrappleGlitchModule and GrappleGlitchModule.IsEnabled() then
			GrappleGlitchModule.Stop()
		end
		if EasyTrimpModule and EasyTrimpModule.IsEnabled() then
			EasyTrimpModule.Stop()
		end

		-- === VISUAL & ESP ===
		if ESP_System and ESP_System.Running then
			ESP_System:Stop()
		end
		if RemoveBarriersModule and RemoveBarriersModule.IsEnabled() then
			RemoveBarriersModule.Stop()
		end
		if BarriersVisibleModule and BarriersVisibleModule.IsEnabled() then
			BarriersVisibleModule.Stop()
		end

		if VisualFeaturesModule then
			VisualFeaturesModule.ToggleCameraStretch(false)
			VisualFeaturesModule.ToggleFullBright(false)
			VisualFeaturesModule.ToggleRemoveFog(false)
		end

		-- === UI EXTRAS ===
		if FPSTimerDisplayModule then
			pcall(function()
				FPSTimerDisplayModule.Cleanup()
			end)
		end
		if ArrayListModule then
			pcall(function()
				ArrayListModule.Cleanup()
			end)
		end
		if EmoteChangerModule then
			EmoteChangerModule.Reset()
		end

		-- === SERVER & GLOBAL ===
		if LagSwitchModule then
			LagSwitchModule.SetEnabled(false)
		end
		if UnlockLeaderboardModule then
			pcall(function()
				UnlockLeaderboardModule.Destroy()
			end)
		end

		if _G.AutoPlaceConnection then
			pcall(function()
				_G.AutoPlaceConnection:Disconnect()
			end)
			_G.AutoPlaceConnection = nil
		end
		if _G.MainCharacterConnection then
			pcall(function()
				_G.MainCharacterConnection:Disconnect()
			end)
			_G.MainCharacterConnection = nil
		end

		print("Script unloaded successfully!")
	end)
end

-- ========================================================================== --
--                        3. KEY SYSTEM UI AT THE BOTTOM                      --
-- ========================================================================== --
local savedKey = loadVerifiedKey()
local autoVerified = false

-- Fungsi pembantu untuk mengecek status premium (SANGAT AKURAT)
local function CheckIfPremium(result)
	if type(result) ~= "table" then
		return false
	end
	if result.is_premium == true then
		return true
	end
	return false
end

-- Auto-Login Process
if savedKey then
	local result = Junkie.check_key(savedKey)
	if result and result.valid then
		_G.IsPremium = CheckIfPremium(result)
		autoVerified = true
		task.spawn(LoadMainHub)
	else
		clearSavedKey()
	end
end

-- If there's no valid key, show the Key System UI
if not autoVerified then
	local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
	local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

	Library.AccentColor = Color3.fromRGB(115, 215, 85)
	Library.MainColor = Color3.fromRGB(25, 25, 25)
	Library.BackgroundColor = Color3.fromRGB(15, 15, 15)
	Library.OutlineColor = Color3.fromRGB(45, 45, 45)

	local KeyWindow = Library:CreateWindow({
		Title = "rzprivate",
		Footer = "t.me/rzprvt | version 3.1",
		Center = true,
		AutoShow = true,
		Size = UDim2.new(0, 550, 0, 320),
	})

	local KeyTabs = { Main = KeyWindow:AddTab("Key System", "key") }
	local KeyGroupBox = KeyTabs.Main:AddLeftGroupbox("Authentication", "keyboard")

	local KolomKey = KeyGroupBox:AddInput("KeyInput", {
		Default = "",
		Numeric = false,
		Finished = false,
		Text = "Input",
		Placeholder = "Enter your key here...",
	})

	KeyGroupBox:AddButton({
		Text = "Verify Key",
		Func = function()
			local inputKey = KolomKey.Value:gsub("%s+", "")

			if inputKey == "" then
				Library:Notify({
					Title = "Warning",
					Description = "Please enter a key first!",
					Time = 3,
				})
				return
			end

			local result = Junkie.check_key(inputKey)

			if result and result.valid then
				_G.IsPremium = CheckIfPremium(result)

				Library:Notify({
					Title = "Key Valid",
					Description = "Authentication successful! Loading main script...",
					Time = 2,
				})

				saveVerifiedKey(inputKey)

				task.delay(1.5, function()
					Library:Unload()
					task.wait(0.5)
					LoadMainHub()
				end)
			else
				Library:Notify({
					Title = "Authentication Failed",
					Description = "The key you entered is invalid or has expired!",
					Time = 3,
				})
			end
		end,
	})

	KeyGroupBox:AddButton({
		Text = "Get Key Link",
		Func = function()
			local keyLink = Junkie.get_key_link()
			if keyLink then
				local success = pcall(function()
					setclipboard(keyLink)
				end)
				if success then
					Library:Notify({ Title = "Copied", Description = "Key link copied to clipboard!", Time = 3 })
				else
					Library:Notify({ Title = "Error", Description = "Clipboard not supported", Time = 3 })
				end
			else
				Library:Notify({ Title = "Error", Description = "Failed to get link from Junkie", Time = 3 })
			end
		end,
	})

	local InfoGroupBox = KeyTabs.Main:AddRightGroupbox("Information", "info")
	InfoGroupBox:AddLabel("Current Game:\nEvade", true)
	InfoGroupBox:AddDivider()
	InfoGroupBox:AddLabel(
		"How to get key?\nClick 'Get Key Link', paste it in your browser, and complete the steps.",
		true
	)
	InfoGroupBox:AddDivider()
	InfoGroupBox:AddLabel("Want a Premium Key?\nBuy on Telegram: @deuznih", true)
	InfoGroupBox:AddDivider()
	InfoGroupBox:AddLabel("Join our community:\nt.me/rzprvt", true)
end
