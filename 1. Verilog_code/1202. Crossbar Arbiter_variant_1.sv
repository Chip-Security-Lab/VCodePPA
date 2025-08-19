//SystemVerilog
// 顶层模块
module crossbar_arbiter #(parameter N=4) (
  input wire clk, rst,
  input wire [N-1:0] src_req,
  input wire [N-1:0] dst_sel [N-1:0],
  output reg [N-1:0] src_gnt,
  output reg [N-1:0] dst_gnt [N-1:0]
);
  // 实例化曼彻斯特进位链加法器
  wire [7:0] a, b, sum;
  wire carry_out;
  
  manchester_adder manchester_adder_inst (
    .a(a),
    .b(b),
    .cin(1'b0),
    .sum(sum),
    .cout(carry_out)
  );
  
  // 实例化仲裁控制器
  wire [N-1:0] src_gnt_next;
  wire [N-1:0] dst_gnt_next [N-1:0];
  
  arbiter_controller #(.N(N)) arbiter_ctrl_inst (
    .rst(rst),
    .src_req(src_req),
    .dst_sel(dst_sel),
    .src_gnt_next(src_gnt_next),
    .dst_gnt_next(dst_gnt_next)
  );
  
  // 实例化寄存器更新逻辑
  register_update #(.N(N)) reg_update_inst (
    .clk(clk),
    .rst(rst),
    .src_gnt_next(src_gnt_next),
    .dst_gnt_next(dst_gnt_next),
    .src_gnt(src_gnt),
    .dst_gnt(dst_gnt)
  );
  
endmodule

// 曼彻斯特进位链加法器模块
module manchester_adder (
  input wire [7:0] a, b,
  input wire cin,
  output wire [7:0] sum,
  output wire cout
);
  wire [7:0] p, g;      // 生成(g)和传播(p)信号
  wire [8:0] c;         // 进位信号，多一位存放初始进位
  
  // 生成传播(p)和生成(g)信号
  assign p = a ^ b;     // 传播信号
  assign g = a & b;     // 生成信号
  
  // 曼彻斯特进位链计算
  assign c[0] = cin;    // 初始进位
  
  // 使用更优化的进位计算逻辑
  carry_chain carry_chain_inst (
    .p(p),
    .g(g),
    .cin(c[0]),
    .c(c[8:1])
  );
  
  // 计算最终和
  assign sum = p ^ c[7:0];
  assign cout = c[8];
  
endmodule

// 进位链计算模块
module carry_chain (
  input wire [7:0] p, g,
  input wire cin,
  output wire [8:1] c
);
  // 第一级进位计算
  assign c[1] = g[0] | (p[0] & cin);
  
  // 第二级进位计算
  assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
  
  // 第三级进位计算
  assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | 
                (p[2] & p[1] & p[0] & cin);
  
  // 第四级进位计算
  assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | 
                (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);
  
  // 第五级进位计算
  assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | 
                (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | 
                (p[4] & p[3] & p[2] & p[1] & p[0] & cin);
  
  // 第六级进位计算
  assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | 
                (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | 
                (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | 
                (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin);
  
  // 第七级进位计算
  assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | 
                (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | 
                (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | 
                (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | 
                (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin);
  
  // 第八级进位计算
  assign c[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | 
                (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | 
                (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | 
                (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | 
                (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | 
                (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin);
endmodule

// 仲裁控制器模块
module arbiter_controller #(parameter N=4) (
  input wire rst,
  input wire [N-1:0] src_req,
  input wire [N-1:0] dst_sel [N-1:0],
  output reg [N-1:0] src_gnt_next,
  output reg [N-1:0] dst_gnt_next [N-1:0]
);
  integer i, j;
  
  always @(*) begin
    // 初始化信号
    src_gnt_next = {N{1'b0}};
    for (i = 0; i < N; i = i + 1) begin
      dst_gnt_next[i] = {N{1'b0}};
    end
    
    // 仲裁逻辑
    if (!rst) begin
      for (i = 0; i < N; i = i + 1) begin
        if (src_req[i]) begin
          for (j = 0; j < N; j = j + 1) begin
            if (dst_sel[i][j] && !dst_gnt_next[j]) begin
              src_gnt_next[i] = 1'b1;
              dst_gnt_next[j][i] = 1'b1;
            end
          end
        end
      end
    end
  end
endmodule

// 寄存器更新模块
module register_update #(parameter N=4) (
  input wire clk, rst,
  input wire [N-1:0] src_gnt_next,
  input wire [N-1:0] dst_gnt_next [N-1:0],
  output reg [N-1:0] src_gnt,
  output reg [N-1:0] dst_gnt [N-1:0]
);
  integer i;
  
  always @(posedge clk) begin
    if (rst) begin
      // 重置逻辑
      src_gnt <= {N{1'b0}};
      for (i = 0; i < N; i = i + 1) begin
        dst_gnt[i] <= {N{1'b0}};
      end
    end else begin
      // 更新寄存器
      src_gnt <= src_gnt_next;
      for (i = 0; i < N; i = i + 1) begin
        dst_gnt[i] <= dst_gnt_next[i];
      end
    end
  end
endmodule