//SystemVerilog
module reset_sync_multi_bit #(
  parameter WIDTH = 4
)(
  input  wire             clk,
  input  wire [WIDTH-1:0] rst_in,
  output reg  [WIDTH-1:0] rst_out
);

  // 创建多级流水线同步复位链
  reg [WIDTH-1:0] stage1_sync;
  reg [WIDTH-1:0] stage2_sync;
  
  // 单独处理每个复位信号，避免使用for循环，更适合FPGA/ASIC结构
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : reset_sync_chain
      // 第一级同步器
      always @(posedge clk or negedge rst_in[i]) begin
        if (!rst_in[i]) begin
          stage1_sync[i] <= 1'b0;
        end else begin
          stage1_sync[i] <= 1'b1;
        end
      end
      
      // 第二级同步器
      always @(posedge clk or negedge rst_in[i]) begin
        if (!rst_in[i]) begin
          stage2_sync[i] <= 1'b0;
        end else begin
          stage2_sync[i] <= stage1_sync[i];
        end
      end
      
      // 输出寄存器
      always @(posedge clk or negedge rst_in[i]) begin
        if (!rst_in[i]) begin
          rst_out[i] <= 1'b0;
        end else begin
          rst_out[i] <= stage2_sync[i];
        end
      end
    end
  endgenerate
  
endmodule