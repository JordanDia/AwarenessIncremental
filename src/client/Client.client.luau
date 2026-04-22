local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local UIRoot = require(ReplicatedStorage.UI.UIRoot)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

Knit.AddControllersDeep(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Controllers"))

Knit.Start({ServicePromises = false}):catch(warn):await()

local screenGui = UIRoot(PlayerGui)

local function PromptPlayerToJoinEvent()

    local success, eventsOrError = pcall(function()
		return SocialService:GetUpcomingExperienceEventsAsync()
	end)
	if not success then
		--warn("Failed to load upcoming events:", eventsOrError)
		return
	end

    local upcomingEvents = eventsOrError

	local selectedEvent
	for _, event in ipairs(upcomingEvents) do
		if not event.HasStarted and not event.HasEnded then
			selectedEvent = event
			break
		end
	end

	if selectedEvent then
		local success, result = pcall(function()
			return SocialService:PromptRsvpToEventAsync(selectedEvent.Id)
		end)
		if not success then
			--warn("RSVP prompt failed:", result)
		end
	else
		--warn("No future events available to prompt.")
		return
	end
end

PromptPlayerToJoinEvent()


task.wait(60)
local gameId = 102479137412335
AvatarEditorService:PromptSetFavorite(gameId, Enum.AvatarItemType.Asset, true)