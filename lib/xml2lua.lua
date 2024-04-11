--- non validating XML stream parser in Lua. It's ugly and needs work
--@author Brad McMahon
local xml2lua = { _VERSION = "0.1" }
local XmlParser = require("XmlParser")

---Instantiates a XmlParser object to parse a XML string

function xml2lua.parser(handler)
    if handler == xml2lua then
        error("You must call xml2lua.parse(handler) instead of xml2lua:parse(handler)")
    end

    local options = {
            --Indicates if whitespaces should be striped or not
            stripWS = 1,
            expandEntities = 1,
            errorHandler = function(errMsg, pos)
                error(string.format("%s [char=%d]\n", errMsg or "Parse Error", pos))
            end
          }

    return XmlParser.new(handler, options)
end


---Gets an _attr element from a table that represents the attributes of an XML tag,
--and generates a XML String representing the attibutes to be inserted
--into the openning tag of the XML
--
--@param attrTable table from where the _attr field will be got
--@return a XML String representation of the tag attributes
local function attrToXml(attrTable)
  local s = ""
  attrTable = attrTable or {}

  for k, v in pairs(attrTable) do
      s = s .. " " .. k .. "=" .. '"' .. v .. '"'
  end
  return s
end

---Gets the first key of a given table
local function getSingleChild(tb)
  local count = 0
  for _ in pairs(tb) do
    count = count + 1
  end
  if (count == 1) then
      for k, _ in pairs(tb) do
          return k
      end
  end
  return nil
end

---Gets the first value of a given table
local function getFirstValue(tb)
  if type(tb) == "table" then
    for _, v in pairs(tb) do
      return v
    end
      return nil
   end

   return tb
end

xml2lua.pretty = true

function xml2lua.getSpaces(level)
  local spaces = ''
  if (xml2lua.pretty) then
    spaces = string.rep(' ', level * 2)
  end
  return spaces
end

function xml2lua.addTagValueAttr(tagName, tagValue, attrTable, level)
  local attrStr = attrToXml(attrTable)
  local spaces = xml2lua.getSpaces(level)
  if (tagValue == '') then
    table.insert(xml2lua.xmltb, spaces .. '<' .. tagName .. attrStr .. '/>')
  else
    table.insert(xml2lua.xmltb, spaces .. '<' .. tagName .. attrStr .. '>' .. tostring(tagValue) .. '</' .. tagName .. '>')
  end
end

function xml2lua.startTag(tagName, attrTable, level)
  local attrStr = attrToXml(attrTable)
  local spaces = xml2lua.getSpaces(level)
  if (tagName ~= nil) then
    table.insert(xml2lua.xmltb, spaces .. '<' .. tagName .. attrStr .. '>')
  end
end

function xml2lua.endTag(tagName, level)
  local spaces = xml2lua.getSpaces(level)
  if (tagName ~= nil) then
    table.insert(xml2lua.xmltb, spaces .. '</' .. tagName .. '>')
  end
end

function xml2lua.isChildArray(obj)
  for tag, _ in pairs(obj) do
    if (type(tag) == 'number') then
      return true
    end
  end
  return false
end

function xml2lua.isTableEmpty(obj)
  for k, _ in pairs(obj) do
    if (k ~= '_attr') then
      return false
    end
  end
  return true
end

return xml2lua
