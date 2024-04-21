--[[

getgenv().configuration = {
    webhook = "",
    serverHopTime = 600,
    titanic = {
        enabled = true,
        normal = 40000000,
        golden = 40000000,
        rainbow = 40000000
    },
    huge = {
        enabled = true,
        normal = 40000000,
        golden = 40000000,
        rainbow = 40000000
    },
    exclusive = {
        enabled = true,
        normal = 40000000,
        golden = 40000000,
        rainbow = 40000000
    },
    custom = {
        ["Titanic Cat"] = {
            normal = 40000000,
            golden = 40000000,
            rainbow = 40000000
        }
    }
}

]]

--// Wait Until The Game Is Loaded

repeat task.wait() until (game:GetService("Players").LocalPlayer)
repeat task.wait() until (not game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("__INTRO"))

--// Initialization

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local httpService = game:GetService("HttpService")
local teleportService = game:GetService("TeleportService")

local localPlayer = players.LocalPlayer
local placeId = game.placeId

local messageLibrary = require(replicatedStorage.Library.Client.Message)
local saveLibrary = require(replicatedStorage.Library.Client.Save)

local boothsBroadcast = replicatedStorage.Network.Booths_Broadcast

local webhookBuilder = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/lilyscripts/webhook-builder/main/webhookBuilder.lua"))()

local categories = {
    ["Enchant"] = {
        replicatedStorage.__DIRECTORY.Enchants:GetChildren(),
        replicatedStorage.__DIRECTORY.Enchants.Exclusive:GetChildren(),
        replicatedStorage.__DIRECTORY.Enchants.Special:GetChildren()
    },
    ["Misc"] = {
        replicatedStorage.__DIRECTORY.MiscItems.Categorized.Admin:GetChildren(),
        replicatedStorage.__DIRECTORY.MiscItems.Categorized.Boosts:GetChildren(),
        replicatedStorage.__DIRECTORY.MiscItems.Categorized.Buffs:GetChildren(),
        replicatedStorage.__DIRECTORY.MiscItems.Categorized.Flags:GetChildren(),
        replicatedStorage.__DIRECTORY.MiscItems.Categorized.Gifts:GetChildren(),
        replicatedStorage.__DIRECTORY.MiscItems.Categorized.Keys:GetChildren(),
        replicatedStorage.__DIRECTORY.MiscItems.Categorized.Miscellaneous:GetChildren(),
        replicatedStorage.__DIRECTORY.MiscItems.Categorized.Tools:GetChildren(),
        replicatedStorage.__DIRECTORY.MiscItems.Categorized.Vouchers:GetChildren(),
        replicatedStorage.__DIRECTORY.MiscItems.Categorized["XP Potions"]:GetChildren()
    },
    ["Charm"] = {
        replicatedStorage.__DIRECTORY.Charms:GetChildren()
    },
    ["Hoverboard"] = {
        replicatedStorage.__DIRECTORY.Hoverboards:GetChildren()
    },
    ["Box"] = {
        replicatedStorage.__DIRECTORY.Boxes:GetChildren()
    },
    ["Currency"] = {
        replicatedStorage.__DIRECTORY.Currency:GetChildren()
    },
    ["Potion"] = {
        replicatedStorage.__DIRECTORY.Potions:GetChildren()
    },
    ["Pet"] = {
        replicatedStorage.__DIRECTORY.Pets.Huge:GetChildren(),
        replicatedStorage.__DIRECTORY.Pets.Titanic:GetChildren(),
        replicatedStorage.__DIRECTORY.Pets.Uncategorized:GetChildren()
    },
    ["Fruit"] = {
        replicatedStorage.__DIRECTORY.Fruits:GetChildren()
    },
    ["Lootbox"] = {
        replicatedStorage.__DIRECTORY.Lootboxes:GetChildren()
    },
    ["Booth"] = {
        replicatedStorage.__DIRECTORY.Booths:GetChildren()
    }
}

--// Prescript

local allIds = {}
local titanics = {}
local huges = {}
local exclusives = {}

for categoryName, categoryPaths in next, categories do
    for _, categoryPath in next, categoryPaths do
        for childName, child in next, categoryPath do
            if (child:IsA("ModuleScript")) then
                local childData = require(child)
                local id = (childData._id or childData.DisplayName)

                if (childData.Tradable ~= false) then
                    allIds[id] = childData.thumbnail
                    if (childData.titanic) then
                        titanics[id] = childData.thumbnail
                    elseif (childData.huge) then
                        huges[id] = childData.thumbnail
                    elseif ((categoryName == "Pet") and (childData.exclusiveLevel)) then
                        exclusives[id] = childData.thumbnail
                    end
                end
            end
        end
    end
end

--// Functions

-- Teleports the user to a non-full, more populated server
local function serverHop()
    local servers = httpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" ..
        tostring(placeId) .. "/servers/Public?sortOrder=Desc&excludeFullGames=true&limit=100")).data
    local server = servers[math.random(1, #servers)]

    return teleportService:TeleportToPlaceInstance(placeId, server.id)
end

-- Displays a message on the player's screen using the message library
local function displayMessage(message, error)
    return messageLibrary.New(message, { err = error })
end

-- Gets the user's diamonds and diamonds uid
local function getDiamonds()
    for currencyUid, currency in next, saveLibrary.Get().Inventory.Currency do
        if currency.id == "Diamonds" then
            return (currency._am or 0), currencyUid
        end
    end

    return 0, ""
end

-- Buys the pet listing
local function buyListing(listing)
    local success, error
    repeat
        success, error = replicatedStorage.Network.Booths_RequestPurchase:InvokeServer(
            listing.playerId,
            {
                [listing.uid] = 1
            }
        )

        if ((error == "Unable to purchase. The seller has left the game.") or (error == "Unable to purchase. That listing has expired!") or (error == "Missing items!")) then
            success = true
        end
    until (success)

    if ((error ~= "Unable to purchase. The seller has left the game.") and (error ~= "Unable to purchase. That listing has expired!") and (error ~= "Missing items!")) then
        local webhook = webhookBuilder(configuration.webhook)
        webhook:setContent("||@everyone @here||")
        webhook:setUsername("lilyscripts - booth sniper (beta)")

        local embed = webhook:createEmbed()
        embed:setTitle("sniped item")
        embed:setDescription("item - " ..
            listing.webhookData.itemName ..
            "\ncost - " .. listing.webhookData.cost .. "\nremaining - " .. listing.webhookData.remaining)
        embed:setUrl("https://discord.gg/S4NHgEVmxy")
        embed:setColor(0)

        embed:setFooter("lilyscripts",
            "https://cdn.discordapp.com/attachments/1217647614007316480/1229193091706261524/nwGmTXT.jpg?ex=662eca46&is=661c5546&hm=0d0780c8e0b3f5b0c6d93367aab46d5d4fe8a0901c7cc70af28e215abd79c542&")

        webhook:send()
    end
end

-- Gets the item's type through id search
local function getItemInfo(itemId)
    -- Add golden support in a later update

    if (titanics[itemId]) then return "titanic", titanics[itemId] end
    if (huges[itemId]) then return "huge", huges[itemId] end
    if (exclusives[itemId]) then return "exclusive", exclusives[itemId] end
    if (allIds[itemId]) then return "normal", allIds[itemId] end
    return nil, nil
end


--// Checks

-- Makes sure the user is in the right game
if ((placeId ~= 15502339080) and (placeId ~= 15588442388)) then
    displayMessage("lilyscripts - you have to be in the trading plaza to execute this script", true)
    return
end

-- Makes sure the user is in the group
if (not localPlayer:IsInGroup(33426684)) then
    displayMessage(
        "lilyscripts - you must join the hairy men fanclub before using the script (copied to your clipboard)", true)
    return
end

-- Make sure all items in their custom configuration actually exists
for itemId, itemSettings in next, configuration.custom do
    if (not allIds[itemId]) then
        displayMessage("lilyscripts - invalid custom configuration (" .. tostring(itemId) .. ")", true)
        return
    end
end

-- Makes sure the server isn't dead (put after check pre-existing booths in later update)

--[[
if (#players:GetPlayers() < 20) then
    serverHop()
    return
end
]]

--// Main Script

-- Get the pre-existing booths in a later update

boothsBroadcast.OnClientEvent:Connect(function(player, data)
    if (data) then
        local listings = data.Listings
        local playerId = data.PlayerID
        local diamonds = getDiamonds()

        for itemUid, item in next, listings do
            if (item.DiamondCost <= diamonds) then
                local itemData = item.ItemData.data
                local itemType, imageId = getItemInfo(item.ItemData.data.id)
                local rarity = ((not item.pt) and ("normal")) or ((item.pt == 1) and ("golden")) or
                    ((item.pt == 2) and ("rainbow"))
                local shiny = (item.sh and "shiny ") or ""
                local listing = {
                    playerId = playerId,
                    uid = itemUid,
                    webhookData = {
                        cost = tostring(item.DiamondCost),
                        remaining = tostring(diamonds - item.DiamondCost),
                        itemName = shiny ..
                            (((rarity ~= "normal") and (rarity .. " ")) or "") .. string.lower(item.ItemData.data.id),
                        imageId = imageId
                    }
                }

                -- Make it purchase custom items that are titanics, huges, exclusives first then proceed in a later update

                if ((itemType == "titanic") and (configuration.titanic.enabled)) then
                    buyListing(listing)
                elseif ((itemType == "huge") and (configuration.huge.enabled)) then
                    buyListing(listing)
                elseif ((itemType == "exclusive") and (configuration.exclusive.enabled)) then
                    buyListing(listing)
                elseif ((itemType == "normal") and (configuration.custom[itemData.id])) then
                    buyListing(listing)
                end
            end
        end
    end
end)

--// Server hop after configuration seconds

task.wait(configuration.serverHopTime)
serverHop()
