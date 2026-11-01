
function! slime#targets#herdr#config() abort
  if !exists("b:slime_config")
    let b:slime_config = {"pane_id": ""}
  endif
  let b:slime_config["pane_id"] = input("herdr pane_id: ", get(b:slime_config, "pane_id", ""))
endfunction

function! slime#targets#herdr#send(config, text) abort
  let [bracketed_paste, text_to_paste, has_crlf] = slime#common#bracketed_paste(a:text)

  if len(text_to_paste) == 0
    return
  endif

  if bracketed_paste
    let text_to_paste = "\e[200~" . text_to_paste . "\e[201~"
  endif
  call s:send_text(a:config["pane_id"], text_to_paste)

  " trailing newline
  if has_crlf
    call s:send_text(a:config["pane_id"], "\r")
  endif
endfunction

function! slime#targets#herdr#ValidEnv() abort
  if !executable("herdr")
    echomsg "vim-slime: herdr is not on your PATH"
    return 0
  endif
  return 1
endfunction

" Reports with echomsg because vim-slime falls back to the default config when this returns 0.
function! slime#targets#herdr#ValidConfig(config, silent) abort
  let pane_id = get(a:config, "pane_id", "")
  if empty(pane_id)
    if !a:silent
      echomsg "vim-slime: herdr pane_id is not set"
    endif
    return 0
  endif
  call system(["herdr", "pane", "get", pane_id])
  if v:shell_error
    if !a:silent
      echomsg "vim-slime: herdr pane " . pane_id . " not found"
    endif
    return 0
  endif
  return 1
endfunction

function! s:send_text(pane_id, text) abort
  let output = system(["herdr", "pane", "send-text", a:pane_id, a:text])
  if v:shell_error
    echoerr "herdr send-text failed: " . output
  endif
endfunction
