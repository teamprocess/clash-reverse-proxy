local _M = {}

function _M.decode(file_path, envname)
    local env_table = {}
    local f = io.open(file_path, "r")
    if not f then return nil, "File not found" end

    for line in f:lines() do
        -- 주석(#)이 아니고 비어있지 않은 라인만 파싱
        local key, value = line:match("^%s*([^#%s=]+)%s*=%s*(.-)%s*$")
        if key and value then
            -- 따옴표 제거 (선택 사항)
            value = value:gsub("^%s*['\"]", ""):gsub("['\"]%s*$", "")
            -- 시스템 환경 변수로 등록하거나 테이블에 저장
            env_table[key] = value
        end
    end
    print(env_table["RECAPTCHA_SECRET_KEY"]) -- 디버깅용 출력
    f:close()
    return env_table[envname]
    
end

return _M