local core            = require("apisix.core")
local local_conf      = require("apisix.core.config_local").local_conf()
local util            = require("apisix.cli.util")
local yaml            = require("tinyyaml")
local ngx_timer_at    = ngx.timer.at
local ngx_timer_every = ngx.timer.every
local log             = core.log
local nodes

local _M = {
    version = 0.1,
}

function _M.nodes(service_name)
    return nodes
end

local function read_file(premature)
    if premature then
        return
    end
    local path = local_conf.discovery and
                           local_conf.discovery.yaml and
                           local_conf.discovery.yaml.path
    local content, err = util.read_file(path)
    if not content then
        log.error("Unable to open YAML discovery configuration file: ", err)
        return
    end
    local nodes_conf, err = yaml.parse(content)
    if not nodes_conf then
        log.error("Invalid YAML discovery configuration file: ", err)
        return
    end
    if not nodes then
        nodes = {}
    end
    for uri, weight in pairs(nodes_conf.nodes) do
        local host_port = {}
        for str in string.gmatch(uri, "[^:]+") do
            table.insert(host_port, str)
        end
        local node = { host = host_port[1], port = tonumber(host_port[2]), weight = weight, }
        table.insert(nodes, node)
    end
end

function _M.init_worker()
    local fetch_interval = local_conf.discovery and
                           local_conf.discovery.yaml and
                           local_conf.discovery.yaml.fetch_interval
    log.info("YAML discovery configuration file fetch interval: ", fetch_interval, ".")
    ngx_timer_at(0, read_file)
    ngx_timer_every(fetch_interval, read_file)
end

return _M
