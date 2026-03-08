#include <string.h>
#include <ctype.h>

// 구조체
typedef struct {
    const char *ip_ptr;
    int ip_len;
} abt_ip_t;

/**
 * xff: 원본 문자열
 * max_find: 찾을 IP 최대 개수 (예: 3개)
 * results: IP 위치와 길이를 담을 구조체 배열
 * return: 실제로 찾은 IP 개수
 */

int xff_parser (const char *xff, int len, int max_find, abt_ip_t *results) {
    // IP 주소 유효성 검사 (혹시나 없거나 그런 상황을 대비)
    if (!xff || len <= 0 || max_find <= 0) {
        return 0; 
    }

    const char *p = xff + len - 1; // *p 포인터 커서에 xff 문자열 메모리 주소 지정 후 +len(길이) - 1로, 뒤의 쓰레기값 제거
    int found_count = 0; // 찾은 IP 개수 (사용자 IP, 프록시1, 프록시2 .. 등등으로 헤더가 요청되기 때문)

    
    // xff 메모리 주소보다 포인터 커서가 크거나 같고, 찾은 IP 개수가 최대 개수보다 작은 동안 반복
    while (p >= xff && found_count < max_find) { 
        // 오른쪽 공백 및 콤마(,) 제거
        while (p >= xff && (isspace(*p) || *p == ',')) p--; // p--를 통해 커서의 데이터 읽는 순서 역방향
        if (p < xff) break; // 문자열의 시작을 벗어나면 종료

        const char *end = p; // IP 주소의 끝 위치 저장, 여기서 end로 변수를 잡아버리면 end는 직접 메모리 주소 할당으로, 또 다른 메모리에 주소값이 복사되어 저장됨 ( 메모리 사용량 증가 )

        // 왼쪽으로 포인터 한글자씩 전진하며 세그먼트 시작점 찾기
        while (p >= xff && *p != ',') p--; // 콤마(,)가 나올 때까지 왼쪽으로 이동
        const char *start = p + 1; // IP 주소의 시작 위치 저장 (콤마 다음부터) 이래야 , 없이 IP 주소가 시작됨

        // 왼쪽 공백 제거
        while (start <= end && isspace(*start)) start++;

        // 시작이 끝보다 작거나 같은 경우에만 결과 배열에 저장 (유효한 IP 주소로 간주)
        if (start <= end) {
            results[found_count].ip_ptr = start; 
            results[found_count].ip_len = (int)(end - start + 1);
            found_count++;
        }
    }

    return found_count; // 실제로 찾은 IP 개수 반환 
}