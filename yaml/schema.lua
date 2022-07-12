return {
    type = "object",
    properties = {
        path = { type = "string", default = "/var/apisix/nodes.yaml" },
        fetch_interval = { type = "integer", minimum = 1, default = 30 },
    },
}