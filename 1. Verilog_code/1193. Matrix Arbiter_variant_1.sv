//SystemVerilog
module matrix_arbiter #(parameter CLIENTS=3) (
  input wire clk,
  input wire [CLIENTS-1:0] req_i,
  output reg [CLIENTS-1:0] gnt_o
);
  // 优先级矩阵
  reg [CLIENTS-1:0] prio [CLIENTS-1:0];
  // 中间变量
  reg [CLIENTS-1:0] req_masked [CLIENTS-1:0];
  reg [CLIENTS-1:0] has_higher_prio_req;
  
  // 初始化和构建优先级矩阵
  always @(*) begin
    for (int i = 0; i < CLIENTS; i++) begin
      prio[i] = {CLIENTS{1'b0}};
      for (int j = 0; j < CLIENTS; j++) begin
        if (i > j) begin
          prio[i][j] = 1'b1; // j比i优先级高
        end
      end
    end
  end
  
  // 计算每个客户端的屏蔽请求
  always @(*) begin
    for (int i = 0; i < CLIENTS; i++) begin
      req_masked[i] = req_i & prio[i];
    end
  end
  
  // 检查是否有更高优先级的请求
  always @(*) begin
    for (int i = 0; i < CLIENTS; i++) begin
      has_higher_prio_req[i] = |req_masked[i];
    end
  end
  
  // 根据优先级规则授予权限
  always @(*) begin
    gnt_o = {CLIENTS{1'b0}}; // 默认不授权
    
    for (int i = 0; i < CLIENTS; i++) begin
      if (req_i[i] && !has_higher_prio_req[i]) begin
        gnt_o[i] = 1'b1;
      end
    end
  end
endmodule