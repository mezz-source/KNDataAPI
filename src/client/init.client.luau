--- Data bootstrapper
--- Just tells DataAPI that player needs to have their data loaded, that's all
local Player = game:GetService("Players")
local LocalPlayer = Player.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DatastoreEvents = ReplicatedStorage:WaitForChild("Datastore")
local LoadClientData = DatastoreEvents:WaitForChild("LoadClientData")

DatastoreEvents.DataLoaded.OnClientEvent:Connect(function(player)
	print("Player data has been loaded")
end)

local dataFolder = LocalPlayer:FindFirstChild("Data")

--- Wait for Data API to be loaded and or hear our request
while not dataFolder do
	local dataFolder = LocalPlayer:FindFirstChild("Data")
	if dataFolder then
		break
	end
	LoadClientData:FireServer()
	print("Waiting...")
	task.wait(3)
end

script:Destroy()
