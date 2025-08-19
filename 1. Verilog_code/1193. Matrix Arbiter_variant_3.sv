//SystemVerilog
module matrix_arbiter #(parameter CLIENTS=3) (
  input wire clk,
  input wire [CLIENTS-1:0] req_i,
  output reg [CLIENTS-1:0] gnt_o
);
  // 并行前缀结构的信号定义
  wire [CLIENTS-1:0] p_stage [0:$clog2(CLIENTS)][0:CLIENTS-1]; 
  wire [CLIENTS-1:0] g_stage [0:$clog2(CLIENTS)][0:CLIENTS-1];
  wire [CLIENTS-1:0] req_mask [CLIENTS-1:0];
  wire [CLIENTS-1:0] gnt_tmp;
  integer i, j;
  
  // 第0级初始化 - 前缀加法器的基础输入
  genvar m, n, k, l;
  generate
    for (m = 0; m < CLIENTS; m = m + 1) begin : gen_init
      for (n = 0; n < CLIENTS; n = n + 1) begin : gen_priority
        if (n < m) begin
          assign p_stage[0][m][n] = 1'b1; // 高优先级标记
          assign g_stage[0][m][n] = req_i[n]; // 高优先级请求传播
        end else begin
          assign p_stage[0][m][n] = 1'b0;
          assign g_stage[0][m][n] = 1'b0;
        end
      end
    end
  endgenerate
  
  // 并行前缀运算 - 类似于并行前缀加法器的结构
  generate
    for (k = 1; k <= $clog2(CLIENTS); k = k + 1) begin : prefix_stages
      for (m = 0; m < CLIENTS; m = m + 1) begin : client_process
        for (n = 0; n < CLIENTS; n = n + 1) begin : bit_process
          // 前缀运算的核心逻辑，类似于Kogge-Stone加法器结构
          if ((n - (1 << (k-1))) >= 0) begin
            assign p_stage[k][m][n] = p_stage[k-1][m][n] | 
                                     (p_stage[k-1][m][n - (1 << (k-1))] & 
                                      p_stage[k-1][m][n]);
            assign g_stage[k][m][n] = g_stage[k-1][m][n] | 
                                     (p_stage[k-1][m][n] & 
                                      g_stage[k-1][m][n - (1 << (k-1))]);
          end else begin
            // 超出范围的位置保持不变
            assign p_stage[k][m][n] = p_stage[k-1][m][n];
            assign g_stage[k][m][n] = g_stage[k-1][m][n];
          end
        end
      end
    end
  endgenerate
  
  // 计算请求掩码 - 使用前缀加法器的结果
  generate
    for (l = 0; l < CLIENTS; l = l + 1) begin : gen_req_mask
      assign req_mask[l] = g_stage[$clog2(CLIENTS)][l][CLIENTS-1:0];
      // 计算授权信号 - 如果有请求且没有更高优先级的请求
      assign gnt_tmp[l] = req_i[l] & ~(|req_mask[l]);
    end
  endgenerate
  
  // 寄存输出以提高时序性能
  always @(posedge clk) begin
    gnt_o <= gnt_tmp;
  end
  
endmodule