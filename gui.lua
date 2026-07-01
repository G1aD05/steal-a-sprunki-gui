-- LIBRARIES
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- FUNCTIONS
local function GetPlayerNames()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(names, player.Name)
    end
    return names
end

local function findBase(name)
    local bases = workspace.Map.Bases:GetChildren()

    for _, _base in bases do
        local sign = _base.Important.Sign.SignPart.SurfaceGui.TextLabel

        if string.gsub(sign.Text, "'s Slot", "") == name then
            return _base
        end
    end
end

local function findPrompt(identifier)
    -- Check if the identifier is already a ProximityPrompt instance
    if typeof(identifier) == "Instance" and identifier:IsA("ProximityPrompt") then
        return identifier
    end
    
    -- Check if the identifier is a direct path
    local prompt = game:GetService("Workspace"):FindFirstChild(identifier)
    if prompt and prompt:IsA("ProximityPrompt") then
        return prompt
    end
    
    -- If not a direct path, search for the prompt by name
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            if descendant.Name == identifier then
                return descendant
            end
        end
    end
    
    return nil
end

local function activatePrompt(identifier)
    local prompt = findPrompt(identifier)
    
    if prompt then
        -- Check if the prompt is enabled and actionable
        if prompt.Enabled and prompt.ActionText ~= "" then
            -- Simulate the input to activate the prompt
            fireproximityprompt(prompt)
            print("[ActivatePrompt] Activated proximity prompt:", prompt.ActionText)
            return true
        else
            print("[ActivatePrompt] Prompt is not enabled or has no action text.")
            return false
        end
    else
        print("[ActivatePrompt] Prompt not found:", identifier)
        return false
    end
end

-- WINDOW
local Window = Rayfield:CreateWindow({
   Name = "Steal a Sprunki",
   Icon = 0,
   LoadingTitle = "Steal a Sprunki GUI",
   LoadingSubtitle = "by Turkey",
   ShowText = "Steal a Sprunki",
   Theme = "Default",

   ToggleUIKeybind = "K",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "Steal a Sprunki GUI"
   },

   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },

   KeySystem = false,
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided",
      FileName = "Key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"Hello"}
   }
})

-- TABS
local Game = Window:CreateTab("Game", 0)
local General = Window:CreateTab("General", 0)

-- VARIABLES
local target
local layer

local player = Players.LocalPlayer
local base = findBase(player.Name)

print("[AutoSteal] FOUND BASE:", base.Name)

local beam = base.Layers["1"].Beams:GetChildren()[1].Beam
local lockPad = base.Layers["1"].LockButton

local position

local originalMinZoom = player.CameraMinZoomDistance
local originalMaxZoom = player.CameraMaxZoomDistance

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- CAMERA
local function ZoomIn()
    player.CameraMinZoomDistance = 5
    player.CameraMaxZoomDistance = 5
end

local function ZoomOut()
    player.CameraMinZoomDistance = originalMinZoom
    player.CameraMaxZoomDistance = originalMaxZoom
end

local function FaceDown()
    local camera = workspace.CurrentCamera
    camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position - Vector3.new(0, 1, 0))
end

-- ELEMENTS
-- Game
-- :: Auto Steal
local Label = Game:CreateLabel("Auto Steal", 0, Color3.fromRGB(51, 51, 51), false) -- Title, Icon, Color, IgnoreTheme

local PlayerDropdown = Game:CreateDropdown({
    Name = "Target",
    Options = GetPlayerNames(),
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "Dropdown1",
    Callback = function(Options)
        target = Options[1]
        print("[Rayfield] TARGET:", target)
    end,
})

local function UpdatePlayerDropdown()
    PlayerDropdown:Refresh(GetPlayerNames())
end

Players.PlayerAdded:Connect(UpdatePlayerDropdown)
Players.PlayerRemoving:Connect(function(player)
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(names, p.Name)
        end
    end
    Dropdown:Refresh(names)
end)

local LayerDropdown = Game:CreateDropdown({
    Name = "Layer",
    Options = {"1", "2", "3", "4", "5", "6", "7"},
    CurrentOption = {"1"},
    MultipleOptions = false,
    Flag = "Dropdown2",
    Callback = function(Options)
        layer = Options[1]
        print("[Rayfield] LAYER:", layer)
    end,
})

local StealButton = Game:CreateButton({
    Name = "Steal",
    Callback = function()
        target_base = findBase(target)

        local slots = target_base.Layers[layer].SlotPads:GetChildren()

        for _, slot in slots do
            local npc = slot:FindFirstChild("Character")
            
            if npc then
                local character = player.Character

                print("[AutoSteal] FOUND NPC:", npc:GetAttribute("CharacterId"))
                FaceDown()
                ZoomIn()

                if character then
                    local hrp = character:FindFirstChild("HumanoidRootPart")

                    if hrp then
                        local npc_hrp = npc:FindFirstChild("HumanoidRootPart")
                        local steal = npc_hrp.SlotPrompt

                        hrp.CFrame = npc_hrp.CFrame
                        task.wait(0.2)
                        activatePrompt(steal)
                        task.wait(0.2)
                        hrp.CFrame = base.Important.RobberyDeposit.CFrame
                        task.wait(1)
                        print("[AutoSteal] STOLE NPC:", npc:GetAttribute("CharacterId"))
                    end
                end
            end
        end
        ZoomOut()
    end,
})

-- :: Auto Lock
local Divider1 = Game:CreateDivider()

local Label = Game:CreateLabel("Auto Lock", 0, Color3.fromRGB(51, 51, 51), false) -- Title, Icon, Color, IgnoreTheme

local AutoLockEnabled = false

local AutoLockToggle = Game:CreateToggle({
    Name = "Lock",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(v)
        AutoLockEnabled = v

        if v then
            task.spawn(function()
                while AutoLockEnabled do
                    print("[AutoLock] CHECKING")
                    if beam.Transparency == 1 then
                        local character = player.Character

                        if character then
                            local hrp = character:FindFirstChild("HumanoidRootPart")

                            if hrp then
                                local position = hrp.CFrame

                                hrp.CFrame = lockPad.CFrame
                                task.wait(0.1)

                                hrp.CFrame = position

                                print("[AutoLock] LOCKED BASE")
                            end
                        end
                    end
                    task.wait(1)
                end
                print("[AutoLock] STOPPED")
            end)
        end
    end,
})

-- General
-- :: Server Hop

local function ServerHop()
    local success, result = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100")
        )
    end)

    if success and result and result.data then
        local servers = {}
        for _, server in ipairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server)
            end
        end

        if #servers > 0 then
            local chosenServer = servers[math.random(1, #servers)]
            TeleportService:TeleportToPlaceInstance(placeId, chosenServer.id, player)
        else
            print("[ServerHop] No available servers found, retrying...")
            task.wait(2)
            ServerHop()
        end
    else
        print("[ServerHop] Failed to fetch server list")
    end
end

local ServerHopButton = General:CreateButton({
    Name = "Server Hop",
    Callback = function()
        ServerHop()
    end
})
