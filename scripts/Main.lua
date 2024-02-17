
THMapCompanion = {}
local THMapCompanion_mt = Class(THMapCompanion, THCore)

local function runScript()
	g_thMapCompanion = THMapCompanion:new()

    g_thMapCompanion:hookFunction(DensityMapHeightManager, "loadMapData", THMapCompanion.DensityMapHeightManager)
end

function THMapCompanion:new()

	local newEnv = THCore:new(THMapCompanion_mt)

    if newEnv ~= nil then
        self.densityMapHeightTypesLoaded = false
    end

    return newEnv
end

THMapCompanion.DensityMapHeightManager = {}

function THMapCompanion.DensityMapHeightManager:hook_loadMapData(superFunc, xmlFile, missionInfo, baseDirectory, ...)
    local success, ra,rb,rc,rd,re = superFunc(self, xmlFile, missionInfo, baseDirectory, ...)

    if success and not g_thMapCompanion.densityMapHeightTypesLoaded then
        local modPath = g_thMapCompanion.modPath
        local modDescFilename = g_thMapCompanion.xmlFilename
        local modDescXMLFile = loadXMLFile("modDescXML", modDescFilename)

        local ttgXMLFilename = getXMLString(modDescXMLFile, "modDesc.densityMapHeightTypes#filename")
        if ttgXMLFilename ~= nil then
            ttgXMLFilename = Utils.getFilename(ttgXMLFilename, modPath)
            if fileExists(ttgXMLFilename) then
                local ttgXMLFile = loadXMLFile("ttgXMLFile", ttgXMLFilename)
                if Utils.getNoNil(ttgXMLFile, 0) ~= 0 then
                    self:loadDensityMapHeightTypes(ttgXMLFile, missionInfo, modPath, false)
                end
            end
        end

        g_thMapCompanion.densityMapHeightTypesLoaded = true
    end

    return success, ra,rb,rc,rd,re
end

runScript()