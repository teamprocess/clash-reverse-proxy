local health_check = require("resty.upstream.healthcheck")
if not health_check then
    ngx.log(ngx.ERR, "Health Check 모듈을 로드할 수 없습니다.")
    return
end


local _M = {}

function _M.check() 
    if ngx.worker.id() == 0 then
        local ok, err = health_check.spawn_checker({
            -- 캐시 메모리 이름
            shm = "health_check",
            -- 서버 주소
            upstream = "backend",
            -- 단순 포트 체크가 아닌 HTTP 요청을 보내서 응답을 확인하는 방식
            type = "http",
            -- 백엔드에 보낼 실제 전문, r\n\r\n은 요청 끝이라는 뜻의 줄바꿈 표시
            http_req = "GET/status HTTP/1.0\r\nHost:clash.kr\r\n\r\n",
            -- 몇초마다 보낼지
            interval = 2000,
            -- 기다려주는 시간
            timeout = 1000,
            -- 최대 연속 실패 횟수
            fall = 3,
            -- 연속 성공 횟수
            rise = 2,
            -- 합격 점수, 200 또는 302 로 와야만 인정
            valid_statuses = {200, 302},
        })

        if not ok then
            -- 타이머 생성 자체가 실패했을 때의 처리
            ngx.log(ngx.ERR, "헬스체크 타이머 생성 실패: ", err)
        end
    end
end

return _M