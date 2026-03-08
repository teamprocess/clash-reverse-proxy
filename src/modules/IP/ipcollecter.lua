local cjson = _G.core.json
local maxminddb = _G.core.maxminddb
local ffi = _G.core.ffi
local ipmatcher = require("modules.resty.ipmatcher")
local customException = require("scripts.exceptions")

local lib_path = ngx.config.prefix() .. "src/modules/lib/libipparser.so"
local ipparser_lib = ffi.load(lib_path)

local _M = {}

-- C ffi 로 작성 예정 
ffi.cdef[[
    typedef struct {
        const char *ip_ptr;
        int ip_len;
    } abt_ip_t;
    int xff_parser (const char *xff, int len, int max_find, abt_ip_t *results);
]]

function _M.ip_collecter() 
    local remote_ip = ngx.var.remote_addr
    local client_xff = ngx.var.http_x_forwarded_for

    if not client_xff then
        ngx.log(ngx.ERR, "X-Forwarded-For 헤더가 없습니다.")
        return customException.customException(ngx.HTTP_FORBIDDEN, "X-Forwarded-For 헤더가 없습니다.")
    end

    local max_find = 5
    local results = ffi.new("abt_ip_t[?]", max_find)

    local count = ipparser_lib.xff_parser(client_xff, #client_xff, max_find, results)

    -- 값이 빈값인지 체크
    if count <= 0 and results[0].ip_ptr == ffi.NULL then
        ngx.log(ngx.ERR, "X-Forwarded-For 헤더에서 유효한 IP 주소를 찾을 수 없습니다.")
        return customException.customException(ngx.HTTP_FORBIDDEN, "X-Forwarded-For 헤더에서 유효한 IP 주소를 찾을 수 없습니다.")
    end

    for i=0, count - 1 do
        local ip = ffi.string(results[i].ip_ptr, results[i].ip_len)
        ngx.log(ngx.ERR, string.format("[%d번 IP] %s", i+1, ip))
    end

    local tcp_ip = ffi.string(results[0].ip_ptr, results[0].ip_len)
    if tcp_ip ~= remote_ip then
        ngx.log(ngx.ERR, string.format("TCP IP와 XFF IP가 다릅니다. TCP IP: %s, XFF IP: %s", remote_ip, tcp_ip))
        return customException.customException(ngx.HTTP_FORBIDDEN, "TCP IP와 XFF IP가 다릅니다.")
    end
end

-- 나중에 function과 모듈 사용해서 예외처리 만들기 ( 만들엇음 )

return _M