
THCore = {}
THCore_mt = Class(THCore)

function THCore:new(mt)
    mt = Utils.getNoNil(mt, THCore_mt)


	local newEnv = setmetatable({}, mt)

    if newEnv ~= nil then
        local modInfo = g_modManager:getModByName(g_currentModName)

        newEnv.modList = g_modManager:getActiveMods()
        newEnv.modInfo = modInfo

        newEnv.modName      = modInfo.modName
        newEnv.modTitle     = modInfo.title
        newEnv.modPath      = modInfo.modDir
        newEnv.xmlFilename  = modInfo.modFile
        newEnv.settingsPath = g_modSettingsDirectory
    end

	return newEnv
end

function THCore:displayMsg(text, ...)
    if type(text) ~= "string" then
		text = string.format("ERROR: Invalid displayMsg text, %q", text)
	end

    local msgString = string.format(">> %s: ", self.modName)..string.format(text, ...)
	print(msgString)
end

function THCore:errorMsg(text, ...)
    if type(text) == "string" then
		text = "ERROR: "..text
	end

	self:displayMsg(text, ...)
	printCallstack()
end

function THCore:msgOnFalse(expression, text, ...)
    if not expression then
        self:errorMsg(text, ...)
        return true
    end

    return false
end

function THCore:argIsInvalid(expression, name, arg)
	if not expression then
		self:errorMsg("Invalid argument %q (%s) in function call", name, arg)
		return true
	end

	return false
end

function THCore:pack(...)
    return {n = select("#", ...), ...}
end

function THCore:unpack(tbl, index)
    index = Utils.getNoNil(index, 1)

    if self:argIsInvalid(type(tbl) == "table", "tbl", tbl)
    or self:argIsInvalid(type(index) == "number" and index > 0, "index", index)
    then
        return
    end

    local numEntries = Utils.getNoNil(tbl.n, #tbl)

    if index <= numEntries then
        return unpack(tbl, index, numEntries)
    end
end

function THCore:toNumber(value)
    local valType = type(value)

    if value == nil or valType == "number" then
        return value
    else
        return tonumber(value)
    end
end

function THCore:toBoolean(value)
    local valType = type(value)

    if value == nil or valType == "boolean" then
        return value
    elseif valType == "string" then
        local valString = string.upper(value)
        if valString == "TRUE" then
            return true
        elseif valString == "FALSE" then
            return false
        end
    end
end

function THCore:getIsType(value, typeList)
    local valType = type(value)

    if valType == typeList then
        return true
    end

    if string.find(typeList, "^"..valType.."|") ~= nil
    or string.find(typeList, "|"..valType.."|") ~= nil
    or string.find(typeList, "|"..valType.."$") ~= nil
    then
        return true
    end

    return false
end

function THCore:getGlobalEnv()
    local globalEnv = getmetatable(_G)

    if type(globalEnv) == "table" then
        return globalEnv.__index
    end
end

function THCore:hookFunction(srcClass, srcFuncName, tgtClass, tgtFuncName, useSelf)
    useSelf = Utils.getNoNil(useSelf, true)

    if self:argIsInvalid(type(srcClass) == "table", "srcClass", srcClass)
    or self:argIsInvalid(type(srcFuncName) == "string", "srcFuncName", srcFuncName)
    or self:argIsInvalid(type(tgtClass) == "table", "tgtClass", tgtClass)
    or self:argIsInvalid(type(useSelf) == "boolean", "useSelf", useSelf)
    then
        return false
    end

    tgtFuncName = Utils.getNoNil(tgtFuncName, "hook_"..srcFuncName)

    if self:argIsInvalid(type(tgtFuncName) == "string", "tgtFuncName", tgtFuncName) then
        return false
    end

    local oldFunc = srcClass[srcFuncName]
    local newFunc = tgtClass[tgtFuncName]

    if self:msgOnFalse(type(oldFunc) == "function", "Cannot find original function %q", srcFuncName)
    or self:msgOnFalse(type(newFunc) == "function", "Cannot find target function %q", tgtFuncName)
    then
        return false
    end

    srcClass[srcFuncName] = function(p1, ...)
        if useSelf then
            return newFunc(p1, oldFunc, ...)
        else
            return newFunc(oldFunc, p1, ...)
        end
    end

    return true
end
