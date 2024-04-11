local function init()
    local obj = {
        root = {},
        options = {noreduce = {}}
    }
    
    obj._stack = {obj.root}  
    return obj  
end


local xmlTree = init()


function xmlTree:new()
    local obj = init()

    obj.__index = self
    setmetatable(obj, self)

    return obj
end


function xmlTree:reduce(node, key, parent)
    for k,v in pairs(node) do
        if type(v) == 'table' then
            self:reduce(v,k,node)
        end
    end
    if #node == 1 and not self.options.noreduce[key] and 
        node._attr == nil then
        parent[key] = node[1]
    end
end

local function convertObjectToArray(obj)
    --#obj == 0 verifies if the field is not an array
    if #obj == 0 then
        local array = {}
        table.insert(array, obj)
        return array
    end

    return obj
end


function xmlTree:starttag(tag)
    local node = {}
    if self.parseAttributes == true then
        node._attr=tag.attrs
    end

    local current = self._stack[#self._stack]
    
    if current[tag.name] then
        local array = convertObjectToArray(current[tag.name])
        table.insert(array, node)
        current[tag.name] = array
    else
        current[tag.name] = {node}
    end

    table.insert(self._stack, node)
end


function xmlTree:endtag(tag, s)
    local prev = self._stack[#self._stack-1]
    if not prev[tag.name] then
        error("XML Error - Unmatched Tag ["..s..":"..tag.name.."]\n")
    end
    if prev == self.root then
        self:reduce(prev, nil, nil)
    end

    table.remove(self._stack)
end

---Parses a tag content.
-- @param t text to process
function xmlTree:text(text)
    local current = self._stack[#self._stack]
    table.insert(current, text)
end

---Parses CDATA tag content.
xmlTree.cdata = xmlTree.text
xmlTree.__index = xmlTree
return xmlTree
