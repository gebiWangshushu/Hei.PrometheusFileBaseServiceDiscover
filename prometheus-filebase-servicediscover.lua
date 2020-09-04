ngx.header.content_type = 'application/json'
local targetFilePath = '/home/website/prometheus/targets.yml' --prometheus targe配置，777权限
local json = require('cjson')

--common metheds
local function fileRead(path)
    local file = io.open(path, 'r')
    local json = file:read('*a')
    file:close()
    return json
end
local function fileWrite(path, content)
    local file = io.open(path, 'w+')
    file:write(content)
    file:close()
end

local function success(msg)
    ngx.say(string.format([[{"code":%d,"message":"%s"}]], 200, msg))
end
local function fail(msg)
    ngx.say(string.format([[{"code":%d,"message":"%s"}]], 300, msg))
end

local function tableKeyFind(tbl, key)
    if tbl == nil then
        return false
    end
    for k, v in pairs(tbl) do
        if k == key then
            return true
        end
    end
    return false
end
local function tableValueFind(tbl, value)
    if tbl == nil then
        return false
    end
    for k, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

local function appFind(configObj, postConfigObj)
    if configObj == nil or postConfigObj == nil then
        print('configObj or postConfigObj can not be nil')
        return false
    end
    for i, v in ipairs(configObj) do
        if v.labels.app == postConfigObj.labels.app then
            return i
        end
    end
    return 0
end

local function registeConfig(configObj, postConfigObj, targetFile)
    local index = appFind(configObj, postConfigObj)

    if index > 0 then
        for i, target in ipairs(postConfigObj.targets) do
            if tableValueFind(configObj[index].targets, target) == false then
                table.insert(configObj[index].targets, target)
            end
        end
        for key, value in pairs(postConfigObj.labels) do
            if tableValueFind(configObj[index].labels, key) == false then
                configObj[index].labels[key] = value
            end
        end
    else
        local config = {targets = postConfigObj.targets, labels = postConfigObj.labels}
        table.insert(configObj, config)
    end

    local newConfig = json.encode(configObj)
    fileWrite(targetFile, newConfig)
    print('更新新配置成功', newConfig)
    return true
end

local function deregisteConfig(configObj, postConfigObj, targetFile)
    local index = appFind(configObj, postConfigObj)
    if index > 0 then
        for i, target in ipairs(configObj[index].targets) do
            if tableValueFind(postConfigObj.targets, target) then
                table.remove(configObj[index].targets, i)
                print('removeremoveremoveremoveremove')
            end
        end

        local len = table.getn(configObj[index].targets)
        if len == 0 then
            table.remove(configObj, index)
        end

        local newConfig = json.encode(configObj)
        fileWrite(targetFile, newConfig)
        print('注销配置成功', newConfig)
        return true
    else
        print('注销配置失败，配置不存在：', postConfigObj.labels.app)
        return false
    end
end
--common metheds end

--main chunk

--read and valid post json config
ngx.req.read_body()
local params = ngx.req.get_body_data()

local postConfigObj = json.decode(params)
if postConfigObj.labels.app == nil then
    return fail('labels.app  不能为空')
end

--init target config
local configFile = fileRead(targetFilePath)
if configFile == nil or configFile == '' then
    configFile = '[]'
end
print('原配置', configFile)

--update config
local configObj = json.decode(configFile)
local result = false
if postConfigObj.type == 'deregiste' then
    result = deregisteConfig(configObj, postConfigObj, targetFilePath)
    if result then
        return success('注销配置成功')
    end
    return fail('注销配置失败,请检查app是否存在')
else
    result = registeConfig(configObj, postConfigObj, targetFilePath)
    return success('注册配置成功')
end
