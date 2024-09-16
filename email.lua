local screenWidth, screenHeight = term.getSize()

-- Color definitions
local colors = {
    default = colors.white,
    prompt = colors.yellow,
    success = colors.green,
    error = colors.red,
    info = colors.cyan,
    background = colors.black
}

local function setColors(foreground, background)
    term.setTextColor(foreground)
    term.setBackgroundColor(background)
end

local function cls()
    setColors(colors.default, colors.background)
    term.clear()
    term.setCursorPos(1, 1)
end

local function getUserInput(prompt)
    setColors(colors.prompt, colors.background)
    term.write(prompt .. ": ")
    setColors(colors.default, colors.background)
    return read()
end

local function getPswd()
    setColors(colors.prompt, colors.background)
    term.write("Password: ")
    setColors(colors.default, colors.background)
    return read("*")
end

-- File paths for saving credentials
local credentialsFilePath = "credentials.txt"
local serverFilePath = "server.txt"

local function saveCredentials(username, password)
    local file = fs.open(credentialsFilePath, "w")
    file.writeLine(username)
    file.writeLine(password)
    file.close()
end

local function loadCredentials()
    if fs.exists(credentialsFilePath) then
        local file = fs.open(credentialsFilePath, "r")
        local username = file.readLine()
        local password = file.readLine()
        file.close()
        return username, password
    end
    return nil, nil
end

local function clearCredentials()
    if fs.exists(credentialsFilePath) then
        fs.delete(credentialsFilePath)
    end
end

local function saveServer(serverID)
    local file = fs.open(serverFilePath, "w")
    file.writeLine(tostring(serverID))
    file.close()
end

local function loadServer()
    if fs.exists(serverFilePath) then
        local file = fs.open(serverFilePath, "r")
        local serverID = tonumber(file.readLine())
        file.close()
        return serverID
    end
    return nil
end

-- Connect to the server
local function connectToServer()
    cls()
    setColors(colors.info, colors.background)
    term.write("Enter server ID: ")
    setColors(colors.default, colors.background)
    local serverID = tonumber(read())
    saveServer(serverID)
    rednet.open("top")
    return serverID
end

-- Change server
local function header(serverID)
    print("--CC:Mail--\n" .. "ServerID - " .. serverID .. "\n")
end

-- Create account
local function createAccount(serverID)
    cls()
    setColors(colors.info, colors.background)
    local username = getUserInput("Username")
    local password = getPswd()

    rednet.send(serverID, textutils.serialize({command = "create", username = username, password = password}))
    local id, response = rednet.receive()
    local data = textutils.unserialize(response)

    setColors(data.success and colors.success or colors.error, colors.background)
    print(data.message)
    setColors(colors.default, colors.background)

    if data.success then
        saveCredentials(username, password)
    end
end

-- Login to account
local function login(serverID)
    cls()
    setColors(colors.info, colors.background)
    local username = getUserInput("Username")
    local password = getPswd()

    rednet.send(serverID, textutils.serialize({command = "login", username = username, password = password}))
    local id, response = rednet.receive()
    local data = textutils.unserialize(response)

    if data.success then
        setColors(colors.success, colors.background)
        print("Login successful!")
        setColors(colors.default, colors.background)
        -- saveCredentials(username, password)
        return username, password
    else
        setColors(colors.error, colors.background)
        print("Login failed.")
        sleep(1)
        setColors(colors.default, colors.background)
        return nil, nil
    end
end

-- Send mail
local function sendMail(serverID, username)
    cls()
    setColors(colors.info, colors.background)
    local recipient = getUserInput("Recipient")
    local message = getUserInput("Message")

    rednet.send(serverID, textutils.serialize({command = "send", sender = username, recipient = recipient, message = message}))
    local id, response = rednet.receive()
    local data = textutils.unserialize(response)

    setColors(colors.success, colors.background)
    print(data.message)
    setColors(colors.default, colors.background)
end

-- Check inbox
local function checkInbox(serverID, username)
    cls()
    setColors(colors.info, colors.background)
    rednet.send(serverID, textutils.serialize({command = "inbox", username = username}))
    local id, response = rednet.receive()
    local data = textutils.unserialize(response)

    if #data.mails > 0 then
        print("Your Inbox:")
        for _, mail in ipairs(data.mails) do
            setColors(colors.default, colors.background)
            print("From: " .. mail.from .. " | Message: " .. mail.message)
        end
    else
        setColors(colors.info, colors.background)
        print("Your inbox is empty.")
    end
    term.setCursorPos(1, screenHeight)
    setColors(colors.default, colors.background)
    term.write("Press any key to continue...")
    os.pullEvent("key")
end

-- Main program
local function main()
    cls()
    local serverID = loadServer()
    if not serverID then
        serverID = connectToServer()
    else
        rednet.open("top")
    end

    -- Automatically login if credentials exist
    local username, password = loadCredentials()
    if username and password then
        rednet.send(serverID, textutils.serialize({command = "login", username = username, password = password}))
        local id, response = rednet.receive()
        local data = textutils.unserialize(response)

        if data.success then
            setColors(colors.success, colors.background)
            print("Automatic login successful!")
            setColors(colors.default, colors.background)
        else
            setColors(colors.error, colors.background)
            print("Automatic login failed.")
            setColors(colors.default, colors.background)
            username, password = nil, nil
        end
    end

    if not username or not password then
        while true do
            cls()
            setColors(colors.info, colors.background)
            header(serverID)
            print("1. Create Account")
            print("2. Login")
            print("3. Quit")
            setColors(colors.default, colors.background)
            term.write("Select an option: ")
            local option = tonumber(read())

            if option == 1 then
                createAccount(serverID)
            elseif option == 2 then
                local newUser, newPass = login(serverID)
                if newUser then
                    username, password = newUser, newPass
                    cls()
                    break
                end
            elseif option == 3 then
                cls()
                break
            end
        end
    end

    if username and password then
        while true do
            cls()
            setColors(colors.info, colors.background)
            header(serverID)
            print("1. Send Mail")
            print("2. Check Inbox")
            print("3. Logout")
            print("4. Exit")
            setColors(colors.default, colors.background)
            term.write("Select an option: ")
            local action = tonumber(read())

            if action == 1 then
                sendMail(serverID, username)
            elseif action == 2 then
                checkInbox(serverID, username)
            elseif action == 3 then
                clearCredentials()
                username, password = nil, nil
                cls()
                break
            elseif action == 4 then
                cls()
                return  -- Exit the program
            end
        end
    end
end

main()
