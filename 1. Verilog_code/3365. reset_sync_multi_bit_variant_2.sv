//SystemVerilog
module reset_sync_multi_bit #(parameter WIDTH = 4) (
  input  wire             clk,
  input  wire [WIDTH-1:0] rst_in,
  output reg  [WIDTH-1:0] rst_out
);
  // 多级流水线寄存器
  reg [WIDTH-1:0] stage1;
  reg [WIDTH-1:0] stage2;
  reg [WIDTH-1:0] stage3;
  
  // 流水线控制信号
  reg stage1_valid, stage2_valid, stage3_valid;
  
  // 第一级流水线 - 输入捕获
  always @(posedge clk or negedge rst_in[0]) begin
    if (!rst_in[0]) begin
      stage1 <= {WIDTH{1'b0}};
      stage1_valid <= 1'b0;
    end else begin
      stage1 <= rst_in;
      stage1_valid <= 1'b1;
    end
  end
  
  // 第二级流水线 - 中间处理
  always @(posedge clk or negedge rst_in[0]) begin
    if (!rst_in[0]) begin
      stage2 <= {WIDTH{1'b0}};
      stage2_valid <= 1'b0;
    end else begin
      stage2 <= stage1;
      stage2_valid <= stage1_valid;
    end
  end
  
  // 第三级流水线 - 输出生成
  always @(posedge clk or negedge rst_in[0]) begin
    if (!rst_in[0]) begin
      stage3 <= {WIDTH{1'b0}};
      stage3_valid <= 1'b0;
    end else begin
      stage3 <= stage2;
      stage3_valid <= stage2_valid;
    end
  end
  
  // 输出注册
  always @(posedge clk or negedge rst_in[0]) begin
    if (!rst_in[0]) begin
      rst_out <= {WIDTH{1'b0}};
    end else if (stage3_valid) begin
      rst_out <= stage3;
    end
  end
endmodule