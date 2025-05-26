make clean
make g++_final
sleep 5

# if only wanna run the score (only use P5)
make -s gem5_public ARGS=P5

# try all of the testcase
# make gem5_public_all
sleep 5

make testbench_public
sleep 5

make score_public
sleep 5