[25/05/26]

- First version of the matrix chain multiplication algoritm
- Pass all of the test cases
  ```bash
  root@64519e651295:/workspace/final# make testbench_public
  Testbench executed
  python3 testbench.py
  P0 succeed
  P1 succeed
  P2 succeed
  P3 succeed
  P4 succeed
  P5 succeed
  ```
- Score:
  ```bash
  root@64519e651295:/workspace/final# make score_public
  Scoring with performance testcases
  python3 score.py
  L1DCache Size: 4096
  L1ICache Size: 4096
  L2Cache Size: 16384
  Test Case 5 Execution Time: 4253765 ns
  Score: 131866715.0
  ```
- also add the c code for easier transformation
