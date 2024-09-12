local users = {}
local mails = {}

-- Load users from file if exists
local function loadUsers()
    if fs.exists("users") then
        local file = fs.open("users", "r")
        users = textutils.unserialize(file.readAll()) or {}
        file.close()
    end
end

-- Save users to file
local function saveUsers()
    local file = fs.open("users", "w")
    file.write(textutils.serialize(users))
    file.close()
end

-- Load mails from file if exists
local function loadMails()
    if fs.exists("mails") then
        local file = fs.open("mails", "r")
        mails = textutils.unserialize(file.readAll()) or {}
        file.close()
    end
end

-- Save mails to file
local function saveMails()
    local file = fs.open("mails", "w")
    file.write(textutils.serialize(mails))
    file.close()
end

-- Add new user
local function createUser(username, password)
    if users[username] then
        return false, "User already exists"
    end
    users[username] = password
    mails[username] = {}
    saveUsers()
    saveMails()
    return true, "Account created successfully"
end

-- Validate user login
local function validateLogin(username, password)
    return users[username] and users[username] == password
end

-- Send mail to user
local function sendMail(sender, recipient, message)
    if not users[recipient] then
        return false, "Recipient does not exist"
    end
    table.insert(mails[recipient], {from = sender, message = message})
    saveMails()
    return true, "Mail sent"
end

-- Get user's mails
local function getMails(username)
    return mails[username] or {}
end

-- Start the server
local function startServer()
    rednet.open("back")
    loadUsers()
    loadMails()

    while true do
        local id, msg = rednet.receive()

        local data = textutils.unserialize(msg)

        if data.command == "create" then
            local success, message = createUser(data.username, data.password)
            rednet.send(id, textutils.serialize({success = success, message = message}))
        
        elseif data.command == "login" then
            local success = validateLogin(data.username, data.password)
            rednet.send(id, textutils.serialize({success = success}))
        
        elseif data.command == "send" then
            local success, message = sendMail(data.sender, data.recipient, data.message)
            rednet.send(id, textutils.serialize({success = success, message = message}))

        elseif data.command == "inbox" then
            local inbox = getMails(data.username)
            rednet.send(id, textutils.serialize({mails = inbox}))
        end
    end
end

startServer()
