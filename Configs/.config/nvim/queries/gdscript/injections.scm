; extends

; Highlight format placeholders (%d, %s, ...) inside strings by injecting
; the printf parser; the gdscript grammar has no nodes for them.
((string) @injection.content
  (#set! injection.language "printf"))
