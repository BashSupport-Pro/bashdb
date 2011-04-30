set trace-co on
# Test bug when journal was running:
#   _Dbg_old_set_opts=hBT -o functrace
# rather than
# _Dbg_old_set_opts='hBT -o functrace'
# Thanks to Nicolai Lissner
step
step
quit
