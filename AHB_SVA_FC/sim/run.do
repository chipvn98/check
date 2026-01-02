#================================================
# FILE: prj_sva_ahb/sim/run.do
#================================================

# Run simulation
run 2000ns

# Save coverage database
coverage save ahb.ucdb

# Stop để mở GUI xem coverage
stop


#onfinish {
#  coverage save ahb.ucdb
#}
#run 2000ns
#stop
