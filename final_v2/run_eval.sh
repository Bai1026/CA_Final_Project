make clean
make g++_final
sleep 2

# if only wanna run the score (only use P5)
# make -s gem5_public ARGS=P5
# try all of the testcase
make gem5_public_all
sleep 2

make testbench_public
# sleep 2

make score_public
# sleep 2