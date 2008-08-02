_Dbg_do_kill() {
  local _Dbg_prompt_output=${_Dbg_tty:-/dev/null}
  read $_Dbg_edit -p "Do hard kill and terminate the debugger? (y/n): " \
      <&$_Dbg_input_desc 2>>$_Dbg_prompt_output

  if [[ $REPLY = [Yy]* ]] ; then 
      kill -9 $$
  fi
}
