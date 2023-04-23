local s = require("say")

s:set_namespace("ko")

-- 'Pending: test.lua @ 12 \n description
s:set("output.pending", "보류")
s:set("output.failure", "실패")
s:set("output.error", "에러")
s:set("output.success", "성공")

s:set("output.pending_plural", "보류")
s:set("output.failure_plural", "실패")
s:set("output.error_plural", "에러")
s:set("output.success_plural", "성공")

s:set("output.pending_zero", "보류")
s:set("output.failure_zero", "실패")
s:set("output.error_zero", "에러")
s:set("output.success_zero", "성공")

s:set("output.pending_single", "보류")
s:set("output.failure_single", "실패")
s:set("output.error_single", "에러")
s:set("output.success_single", "성공")

s:set("output.seconds", "초")

s:set("output.no_test_files_match", "Lua 패턴과 일치하는 테스트 파일을 찾을 수 없습니다: %s")
s:set("output.file_not_found", "파일 또는 디렉토리를 찾을 수 없습니다: %s")

-- definitions following are not used within the 'say' namespace
return {
  failure_messages = {
    "%d 개의 스펙이 엉망이야",
    "스펙이 엉망이야",
    "코드가 별로야 반성해",
    "코드가 위험 구역에 있어",
    "테스트를 안하는게 나을 수도 있어",
    "우리 할머니도 386에서 더 나은 테스트를 작성했어",
    "매번 실패하니까 맥주나 마시자",
    "유감이야 친구",
  },
  success_messages = {
    "아싸, 스펙 통과",
    "괜찮아, 테스트가 있어",
    "느낌이 좋아",
    "대성공",
    "테스트 통과, 맥주나 마시자",
  },
}
