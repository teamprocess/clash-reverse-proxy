local _M = {}

local http = _G.core.http
local cjson = _G.core.cjson
local key = _G.core.recaptcha_secret_key
local customException = require("scripts.exceptions")




-- reCAPTCHA 검증 함수, 모듈화 햇음
function _M.verify(token)
    
    -- 토큰 값이 널이 아닌지, 위조된것이 아닌지 확인
    if not token or token == "" then
        return customException.customException(ngx.HTTP_BAD_REQUEST, "reCAPTCHA 토큰이 제공되지 않았습니다.")
    end

    local httpc = http.new()

    -- 1초 타임아웃 설정 | 연결, 읽기, 쓰기 타임아웃
    httpc:set_timeout(1000, 1000, 1000) 

    -- reCAPTCHA API 연결 및 검증 요청.
    local res, err = httpc:request_uri("https://www.google.com/recaptcha/api/siteverify", {
        method = "POST",
        body = "secret=" .. key .. "&response=" .. token,
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded"
        },
        ssl_verify = true -- ssl 인증서 확인, 비정상적인 요청 검열 위해 설정
    })

    if not res then
        ngx.log(ngx.ERR, "reCAPTCHA API 요청 실패: ", err)
        return true, customException.customException(ngx.HTTP_INTERNAL_SERVER_ERROR, "reCAPTCHA 검증 중 오류가 발생했습니다.")
    end

    local data = cjson.decode(res.body)
    if not data or type(data) ~= "table" then
        ngx.log(ngx.ERR, "reCAPTCHA API 응답 디코딩 실패")
        return customException.customException(ngx.HTTP_INTERNAL_SERVER_ERROR, "reCAPTCHA 검증 중 오류가 발생했습니다.")
    end

    if data.success then
        local score = data.score or 0
        if score >= 0.5 then
            return true, score
        else
            ngx.log(ngx.WARN, "reCAPTCHA 검증 실패: 낮은 점수 (", score, ")")
            return customException.customException(ngx.HTTP_FORBIDDEN, "reCAPTCHA 검증 실패: 낮은 점수")
        end
    end
    
end

return _M