local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- CÀI ĐẶT
local Settings = {
AimbotEnabled = true,
TeamCheck = false,
VisibilityCheck = true,
AimPart = "Head",
FovRadius = 300,
Smoothness = 0.2,
Keybind = Enum.KeyCode.V,
ESPEnabled = true
}

-- TẠO GUI CHÍNH (menu + ESP)
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "AimbotESP_Menu"
mainGui.ResetOnSpawn = false
mainGui.Parent = playerGui

-- ========== ESP (không cần Drawing) ==========
local espElements = {} -- [player] = {box, name, healthBar}

local function GetPlayerColor(player)
if player.Team then
return player.Team.TeamColor.Color
end
return Color3.fromRGB(255,255,255)
end

local function CreateESPForPlayer(player)
if espElements[player] then return end

local box = Instance.new("Frame")
box.Size = UDim2.new(0, 100, 0, 200)
box.BackgroundTransparency = 0.8
box.BorderSizePixel = 2
box.BorderColor3 = GetPlayerColor(player)
box.BackgroundColor3 = Color3.fromRGB(0,0,0)
box.Visible = true
box.Parent = mainGui

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(0, 100, 0, 20)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = GetPlayerColor(player)
nameLabel.TextStrokeTransparency = 0.5
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 12
nameLabel.Text = player.Name
nameLabel.Parent = box

local healthBar = Instance.new("Frame")
healthBar.Size = UDim2.new(1, 0, 0, 4)
healthBar.Position = UDim2.new(0,0,1, -4)
healthBar.BackgroundColor3 = Color3.fromRGB(255,0,0)
healthBar.BorderSizePixel = 0
healthBar.Parent = box

espElements[player] = {
Box = box,
Name = nameLabel,
HealthBar = healthBar
}
end

local function RemoveESPForPlayer(player)
local elements = espElements[player]
if elements then
elements.Box:Destroy()
espElements[player] = nil
end
end

local function UpdateAllESP()
if not Settings.ESPEnabled then
for _, elements in pairs(espElements) do
elements.Box.Visible = false
end
return
end

for player, elements in pairs(espElements) do
if player and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
local character = player.Character
local humanoid = character.Humanoid
local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
local head = character:FindFirstChild("Head")

if rootPart and head then
local headPos = head.Position
local footPos = rootPart.Position - Vector3.new(0, 2, 0)

local headScreen, headOn = Camera:WorldToScreenPoint(headPos)
local footScreen, footOn = Camera:WorldToScreenPoint(footPos)

if headOn and footOn then
local height = math.abs(footScreen.Y - headScreen.Y)
local width = height * 0.4
local xPos = headScreen.X - width/2
local yPos = headScreen.Y

elements.Box.Position = UDim2.new(0, xPos, 0, yPos)
elements.Box.Size = UDim2.new(0, width, 0, height)
elements.Box.BorderColor3 = GetPlayerColor(player)
elements.Box.Visible = true

elements.Name.Position = UDim2.new(0, 0, 0, -18)
elements.Name.Size = UDim2.new(1, 0, 0, 16)
elements.Name.Text = player.Name .. " [" .. math.floor(humanoid.Health) .. "]"
elements.Name.TextColor3 = GetPlayerColor(player)

local healthPercent = humanoid.Health / humanoid.MaxHealth
elements.HealthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
if healthPercent < 0.3 then
elements.HealthBar.BackgroundColor3 = Color3.fromRGB(255,0,0)
elseif healthPercent < 0.6 then
elements.HealthBar.BackgroundColor3 = Color3.fromRGB(255,255,0)
else
elements.HealthBar.BackgroundColor3 = Color3.fromRGB(0,255,0)
end
else
elements.Box.Visible = false
end
else
elements.Box.Visible = false
end
else
elements.Box.Visible = false
end
end
end

-- Xử lý khi player xuất hiện/biến mất
local function OnPlayerAdded(player)
if player ~= LocalPlayer then
CreateESPForPlayer(player)
player.CharacterAdded:Connect(function()
CreateESPForPlayer(player)
end)
end
end

local function OnPlayerRemoving(player)
RemoveESPForPlayer(player)
end

for _, player in ipairs(Players:GetPlayers()) do
if player ~= LocalPlayer then
OnPlayerAdded(player)
end
end
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

-- ========== AIMBOT ==========
local function GetClosestPlayer()
local closest = nil
local shortestDist = Settings.FovRadius
local mouseLocation = UserInputService:GetMouseLocation()
local cameraCF = Camera.CFrame

for _, player in ipairs(Players:GetPlayers()) do
if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end

local aimPart = player.Character:FindFirstChild(Settings.AimPart)
if not aimPart then aimPart = player.Character:FindFirstChild("HumanoidRootPart") end
if not aimPart then continue end

local screenPos, onScreen = Camera:WorldToScreenPoint(aimPart.Position)
if not onScreen then continue end

if Settings.VisibilityCheck then
local ray = Ray.new(cameraCF.Position, (aimPart.Position - cameraCF.Position).Unit * 500)
local hit = workspace:FindPartOnRay(ray, LocalPlayer.Character)
if hit and not hit:IsDescendantOf(player.Character) then continue end
end

local vector = Vector2.new(screenPos.X - mouseLocation.X, screenPos.Y - mouseLocation.Y)
local dist = vector.Magnitude
if dist < shortestDist then
shortestDist = dist
closest = aimPart
end
end
end
return closest
end

local function SmoothLookAt(targetPos)
local currentCF = Camera.CFrame
local targetCF = CFrame.new(currentCF.Position, targetPos)
local newCF = currentCF:Lerp(targetCF, Settings.Smoothness)
Camera.CFrame = newCF
end

-- ========== MENU GIAO DIỆN ==========
local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 220, 0, 110)
menuFrame.Position = UDim2.new(1, -230, 0, 10)
menuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
menuFrame.BackgroundTransparency = 0.15
menuFrame.BorderSizePixel = 1
menuFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
menuFrame.Active = true
menuFrame.Draggable = true
menuFrame.Parent = mainGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Aimbot, ESP by MerzyThanh"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = menuFrame

local aimbotButton = Instance.new("TextButton")
aimbotButton.Size = UDim2.new(0.8, 0, 0, 30)
aimbotButton.Position = UDim2.new(0.1, 0, 0, 30)
aimbotButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
aimbotButton.Text = "AIMBOT: BẬT"
aimbotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
aimbotButton.Font = Enum.Font.Gotham
aimbotButton.TextSize = 14
aimbotButton.Parent = menuFrame

local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(0.8, 0, 0, 30)
espButton.Position = UDim2.new(0.1, 0, 0, 65)
espButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
espButton.Text = "ESP: BẬT"
espButton.TextColor3 = Color3.fromRGB(255, 255, 255)
espButton.Font = Enum.Font.Gotham
espButton.TextSize = 14
espButton.Parent = menuFrame

-- Sự kiện nút bấm
aimbotButton.MouseButton1Click:Connect(function()
Settings.AimbotEnabled = not Settings.AimbotEnabled
if Settings.AimbotEnabled then
aimbotButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
aimbotButton.Text = "AIMBOT: BẬT"
else
aimbotButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
aimbotButton.Text = "AIMBOT: TẮT"
end
end)

espButton.MouseButton1Click:Connect(function()
Settings.ESPEnabled = not Settings.ESPEnabled
if Settings.ESPEnabled then
espButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
espButton.Text = "ESP: BẬT"
else
espButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
espButton.Text = "ESP: TẮT"
for _, elements in pairs(espElements) do
elements.Box.Visible = false
end
end
end)

-- Phím tắt V
UserInputService.InputBegan:Connect(function(input, gameProcessed)
if gameProcessed then return end
if input.KeyCode == Settings.Keybind then
Settings.AimbotEnabled = not Settings.AimbotEnabled
if Settings.AimbotEnabled then
aimbotButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
aimbotButton.Text = "AIMBOT: BẬT"
else
aimbotButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
aimbotButton.Text = "AIMBOT: TẮT"
end
end
end)

-- Khởi tạo trạng thái nút ban đầu
if not Settings.AimbotEnabled then
aimbotButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
aimbotButton.Text = "AIMBOT: TẮT"
end
if not Settings.ESPEnabled then
espButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
espButton.Text = "ESP: TẮT"
end

-- Vòng lặp chính: aimbot + cập nhật ESP
RunService.RenderStepped:Connect(function()
if Settings.AimbotEnabled then
local target = GetClosestPlayer()
if target then
SmoothLookAt(target.Position)
end
end
UpdateAllESP()
end)

print("Đã tải xong: Aimbot + ESP (không cần Drawing) + Menu. Phím V để bật/tắt Aimbot.")
