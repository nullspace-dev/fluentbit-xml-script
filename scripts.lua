local xml2lua = require("xml2lua")
local handler = require("tree")
local json = require("json")

function buildKVPair(data, masterRecord, key)
    if type(data) == "table" then
        for k, v in pairs(data) do
            if k == "EventID" and type(v) == "table" then
                masterRecord[k] = v[1]
            else
                buildKVPair(v, masterRecord, k)
            end
        end
    else
        masterRecord[key] = data
    end
end

function eventDataPair(data, masterRecord)
    for k, v in pairs(data.Data) do
        masterRecord[v["_attr"]["Name"]] = v["1"]
    end
end

-- I found it nessicary to base64 log sets so data isn't lost due to formating
function b64enc(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    return ((data:gsub(
        ".",
        function(x)
            local r, b = "", x:byte()
            for i = 8, 1, -1 do
                r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
            end
            return r
        end
    ) .. "0000"):gsub(
        "%d%d%d?%d?%d?%d?",
        function(x)
            if (#x < 6) then
                return ""
            end
            local c = 0
            for i = 1, 6 do
                c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
            end
            return b:sub(c + 1, c + 1)
        end
    ) .. ({"", "==", "="})[#data % 3 + 1])
end

-- This function was added as we noticed with the current XML parser meta data in the XML tag would place the value's field name as integer in a table which is seems fluentbit (we think) expects all strings as field names where there are strings and interpertis it as a empty string. A better fix in the XML parser will com in later but this at least allows the log to be passed correctly
function sanityCheckKeysandLog(outputingRecords)
    local output = {}
    for k, v in pairs(outputingRecords) do
        if type(k) ~= "string" then
            --os.execute(psCmd)
            local key = tostring(k)
            output["debug-" .. key] = v

            local psCmd =
                'powershell.exe -Command `Write-EventLog -LogName "Application" -Source "Application Error" -EventID 3045 -EntryType Information -Message "Fluentbit script parsed out event with an unexpected key result: ' ..
                key .. "\n B64 dataset: \n " .. b64enc(json.encode(outputingRecords)) .. '" -Category 1 -RawData 10,20`'
            print(psCmd)
        else
            output[k] = v
        end
    end
    return output
end

function parseXml(tag, timestamp, record)
    new_record = record
    local systemInsert = new_record.System
    local parser = xml2lua.parser(handler)
    parser:parse(systemInsert)
    local event = handler.root.Event

    local eventTable = {}
    if event[1] ~= nil then
        eventTable = event[#event]
    else
        eventTable = event
    end
    new_record["System"] = nil
    --file:write("eventTable: \n" .. json.encode(eventTable.EventData.Data) .. "\n")
    if eventTable.System ~= nil then
        buildKVPair(eventTable.System, new_record, "")
    end

    if eventTable.EventData ~= nil then
        if eventTable.EventData.Data ~= nil then
            if eventTable.EventData.Data[1] ~= nil then
                if eventTable.EventData.Data[1]["_attr"] ~= nil then
                    for k, v in pairs(eventTable.EventData.Data) do
                        new_record[v["_attr"]["Name"]] = v[1]
                    end
                else
                    new_record["EventData"] = json.encode(eventTable.EventData.Data)
                end
            end
        else
            new_record["EventData"] = json.encode(eventTable.EventData)
        end
    end

    if eventTable.UserData ~= nil then
        buildKVPair(eventTable.UserData.RuleAndFileData, new_record, "")
    end
    --file:close()
    stringInsert = new_record["StringInserts"]
    new_record["username"] = stringInsert[6]

    local output = sanityCheckKeysandLog(new_record)
    return 1, timestamp, output
end

function enrich_login_logs(tag, timestamp, record)
    new_record = record
    new_record["hour_of_day"] = os.date("%H")
    return 1, timestamp, new_record
end
