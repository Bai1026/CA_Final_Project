# Final Project: Matrix Chain Multiplication

## 一、專案目標

1. **實作目標**
   - 在 RISC-V 組合語言中實作  
     `chain_matrix_multiplication(int** matrices, int* rows, int* cols, int count)`
   - 計算最優矩陣鏈相乘順序並產生最終結果矩陣
   - 結果矩陣指標放入 `a0`，函式返回該位址
2. **效能評分**  
   根據模擬時間 `T` 與快取大小 `S_{L1I}`, `S_{L1D}`, `S_{L2}` 計算：  
    `Score = T × ( log2(S_L1I) + log2(S_L1D) + ½ log2(S_L2) )⁻¹`
   - **目標：最小化** Score

---

## 二、輸入／輸出規格

- **輸入**（RISC-V calling convention）
   - `a0` = `int** matrices`：N 個矩陣資料起始位址陣列
   - `a1` = `int* rows` ：每個矩陣的列數陣列
   - `a2` = `int* cols` ：每個矩陣的行數陣列
   - `a3` = `int count` ：矩陣個數 N
- **輸出**
   - `a0` = `int* ret` ：計算後結果矩陣起始位址

---

## 三、作業流程與修改檔案

1. **環境準備**
   ```bash
   docker start -i <container_name>
   cd /workspace
   mkdir final && cd final
   # 放入提供之所有檔案
   ```
2. **編輯快取參數**
   修改 gem5_args.conf：

   ```bash
   GEM5_ARGS = --l1i_size 16kB --l1i_assoc 4 \
               --l1d_size 16kB --l1d_assoc 4 \
               --l2_size 128kB --l2_assoc 8
   ```

3. **實作核心演算法**

- 在 matrix_chain_multiplication.s 中：
  - 動態規劃（DP）選擇最佳乘法順序
  - 呼叫 malloc 配置暫存矩陣
  - 實作實際相乘（三重迴圈／tiling）

4. **編譯與功能驗證**

   ```bash
   make g++_final
   make testbench_public
   ```

5. **效能模擬與評分**

   ```bash
   make gem5_public_all
   make score_public
   ```

6. **報告**
   - report.pdf（1–2 頁）：
     - 演算法設計與優化技巧
     - 快取參數決策依據
     - 團隊分工與心得

---

## 四、文件與繳交

- 結構
  ```bash
  teamID_final/
  ├─ matrix_chain_multiplication.s
  ├─ gem5_args.conf
  └─ report.pdf
  ```
- 壓縮檔命名：<teamID>\_final_v<版本>.zip
- 繳交：NTUCOOL
- 期限：2025/6/8 23:59:59 (UTC+8)
