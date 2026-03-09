local ip_collecter = require("modules.IP.ipcollecter")
local customException = require("scripts.exceptions")
local recaptcha = require("utils.reCAPTCHA")

local _M = {}

function _M.authenticate()

    -- ip 추출기
    ip_collecter.collect()

    -- 헤더에서 리캡차 토큰 추출
    local recaptcha_token = ngx.req.get_headers()["X-Recaptcha-Token"]
    if not recaptcha_token then
        return customException.customException(ngx.HTTP_BAD_REQUEST, "reCAPTCHA 토큰이 제공되지 않았습니다.")
    end

    -- 리캡차
    local success, score_or_err = recaptcha.verify(recaptcha_token)
    if not success then
        return customException.customException(ngx.HTTP_FORBIDDEN, "reCAPTCHA 검증 실패: " .. tostring(score_or_err))
    end

    ngx.log(ngx.INFO, "[AUTH] reCAPTCHA Passed. Score: ", score_or_err)

    return true
end


return _M

