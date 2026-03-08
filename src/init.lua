_G.core = {}


-- 라이브러리 모듈 로드, 한번에 로드해서 불필요한 메모리 사용 절약
_G.core.http = require("resty.http")
_G.core.cjson = require("cjson.safe")
_G.core.redis = require("resty.redis")
_G.core.ffi = require("ffi")


-- reCAPTCHA v3 키 불러오기

_G.core.recaptcha_secret_key = "" -- 후에 osgetenv으로 도커에서 불러올 예정
if _G.core.recaptcha_secret_key == nil then
    ngx.log(ngx.ERR, "reCAPTCHA 시크릿 키가 설정되지 않았습니다.")
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    local response = {
        error_code = "라이브러리 초기화 에러",
        message = "reCAPTCHA 시크릿 키가 설정되지 않았습니다."
    }
    ngx.say(_G.core.json.encode(response))
    return ngx.exit(500)
end

-- 후에 maxminddb 설정
local prefix = ngx.config.prefix()
local maxminddb = require("resty.maxminddb")
package.path = prefix .. "?.lua;" .. package.path

local ok, err = maxminddb.init(prefix .. "data/GeoLite2-Country.mmdb")

if not ok then
    ngx.log(ngx.ERR, "MaxMindDB 초기화 실패: ", err)
else
    _G.core.maxminddb = maxminddb
    ngx.log(ngx.INFO, "MaxMindDB 초기화 성공")
end

-- 초기화 로그
ngx.log(ngx.INFO, "라이브러리 초기화 완료")