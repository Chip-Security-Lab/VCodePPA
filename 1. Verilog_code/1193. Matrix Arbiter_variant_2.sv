//SystemVerilog
module matrix_arbiter #(parameter CLIENTS=3) (
  input wire clk,
  input wire [CLIENTS-1:0] req_i,
  output reg [CLIENTS-1:0] gnt_o
);
  // 优先级矩阵
  reg [CLIENTS-1:0] prio_matrix [CLIENTS-1:0];
  // 中间变量，用于存储冲突检测结果
  reg [CLIENTS-1:0] conflict_detect;
  // 循环变量
  integer i, j;
  
  always @(*) begin
    // 步骤1: 初始化优先级矩阵
    for (i = 0; i < CLIENTS; i = i + 1) begin
      prio_matrix[i] = {CLIENTS{1'b0}};
    end
    
    // 步骤2: 设置优先级关系
    for (i = 0; i < CLIENTS; i = i + 1) begin
      for (j = 0; j < CLIENTS; j = j + 1) begin
        // 当i > j时，i比j优先级低
        if (i > j) begin
          prio_matrix[i][j] = 1'b1;
        end
      end
    end
    
    // 步骤3: 初始化输出授权信号
    gnt_o = {CLIENTS{1'b0}};
    
    // 步骤4: 计算每个客户端的冲突检测结果
    for (i = 0; i < CLIENTS; i = i + 1) begin
      // 检测是否有更高优先级的请求
      conflict_detect[i] = |(req_i & prio_matrix[i]);
      
      // 步骤5: 根据请求和冲突检测来决定授权
      if (req_i[i] && !conflict_detect[i]) begin
        gnt_o[i] = 1'b1;
      end else begin
        gnt_o[i] = 1'b0;
      end
    end
  end
endmodule