//SystemVerilog
module fixed_priority_arbiter #(parameter N=8) (
  input wire clk, rst_n,
  input wire [N-1:0] req,
  output reg [N-1:0] grant
);
  wire [N-1:0] priority_mask;
  wire [N-1:0] masked_req;
  wire [N-1:0] next_grant;
  
  // Brent-Kung优先级编码器实现
  brent_kung_priority_encoder #(.WIDTH(N)) bk_encoder (
    .req(req),
    .priority_mask(priority_mask)
  );
  
  // 屏蔽低优先级请求
  assign masked_req = req & priority_mask;
  
  // 生成授权信号
  assign next_grant = (|req) ? masked_req : {N{1'b0}};
  
  // 寄存器更新授权信号
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant <= {N{1'b0}};
    end
    else begin
      grant <= next_grant;
    end
  end
endmodule

// Brent-Kung优先级编码器
module brent_kung_priority_encoder #(parameter WIDTH=8) (
  input wire [WIDTH-1:0] req,
  output wire [WIDTH-1:0] priority_mask
);
  // 生成传播信号(P)与生成信号(G)
  wire [WIDTH-1:0] P;
  wire [WIDTH-1:0] G;
  
  // 第一阶段：计算初始P和G信号
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg_init
      assign P[i] = req[i];
      assign G[i] = (i == 0) ? req[i] : 1'b0;
    end
  endgenerate
  
  // 第二阶段：Brent-Kung树形结构计算优先级
  wire [WIDTH-1:0] group_P [0:3]; // log2(WIDTH)级传播信号
  wire [WIDTH-1:0] group_G [0:3]; // log2(WIDTH)级生成信号
  
  // 复制初始信号到第0级
  assign group_P[0] = P;
  assign group_G[0] = G;
  
  // 预计算后续级联
  generate
    // 第1级：2位一组
    for (i = 0; i < WIDTH; i = i + 2) begin : gen_level1
      if (i+1 < WIDTH) begin
        assign group_P[1][i] = group_P[0][i];
        assign group_G[1][i] = group_G[0][i];
        
        assign group_P[1][i+1] = group_P[0][i+1] & group_P[0][i];
        assign group_G[1][i+1] = group_G[0][i+1] | (group_P[0][i+1] & group_G[0][i]);
      end else begin
        assign group_P[1][i] = group_P[0][i];
        assign group_G[1][i] = group_G[0][i];
      end
    end
    
    // 第2级：4位一组
    for (i = 0; i < WIDTH; i = i + 4) begin : gen_level2
      assign group_P[2][i] = group_P[1][i];
      assign group_G[2][i] = group_G[1][i];
      
      if (i+1 < WIDTH) begin
        assign group_P[2][i+1] = group_P[1][i+1];
        assign group_G[2][i+1] = group_G[1][i+1];
      end
      
      if (i+2 < WIDTH) begin
        assign group_P[2][i+2] = group_P[1][i+2];
        assign group_G[2][i+2] = group_G[1][i+2];
      end
      
      if (i+3 < WIDTH) begin
        assign group_P[2][i+3] = group_P[1][i+3] & group_P[1][i+1];
        assign group_G[2][i+3] = group_G[1][i+3] | (group_P[1][i+3] & group_G[1][i+1]);
      end
    end
    
    // 第3级：8位一组 (最终级)
    for (i = 0; i < WIDTH; i = i + 8) begin : gen_level3
      for (genvar j = 0; j < 7 && i+j < WIDTH; j = j + 1) begin : copy_previous
        assign group_P[3][i+j] = group_P[2][i+j];
        assign group_G[3][i+j] = group_G[2][i+j];
      end
      
      if (i+7 < WIDTH) begin
        assign group_P[3][i+7] = group_P[2][i+7] & group_P[2][i+3];
        assign group_G[3][i+7] = group_G[2][i+7] | (group_P[2][i+7] & group_G[2][i+3]);
      end
    end
  endgenerate
  
  // 第三阶段：优先级掩码生成
  wire [WIDTH-1:0] priority_select;
  
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : gen_priority_mask
      if (i == 0) begin
        assign priority_select[i] = 1'b1;
      end else begin
        assign priority_select[i] = ~(|group_G[3][i-1:0]);
      end
      assign priority_mask[i] = req[i] & priority_select[i];
    end
  endgenerate
  
endmodule