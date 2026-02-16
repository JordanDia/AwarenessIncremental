local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local UIRoot = require(ReplicatedStorage.UI.UIRoot)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

Knit.AddControllersDeep(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Controllers"))

Knit.Start({ServicePromises = false}):catch(warn):await()

local screenGui = UIRoot(PlayerGui)
