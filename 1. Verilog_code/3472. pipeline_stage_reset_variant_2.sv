//SystemVerilog
module pipeline_stage_reset #(parameter WIDTH = 32)(
  input clk, rst,
  input [WIDTH-1:0] data_in,
  input valid_in,
  output reg [WIDTH-1:0] data_out,
  output reg valid_out
);
  wire [7:0] subtractor_in_a;
  wire [7:0] subtractor_in_b;
  wire [7:0] subtractor_result;
  
  // 中间流水线寄存器
  reg [WIDTH-1:16] data_upper_pipe;
  reg [7:0] subtractor_in_b_pipe;
  reg valid_pipe;
  
  // Extract 8-bit portions for subtraction operation
  assign subtractor_in_a = data_in[7:0];
  assign subtractor_in_b = data_in[15:8];
  
  // Two's complement subtraction implementation with pipelined structure
  twos_complement_subtractor u_subtractor (
    .a(subtractor_in_a),
    .b(subtractor_in_b),
    .result(subtractor_result)
  );
  
  // 第一级流水线：捕获输入数据
  always @(posedge clk) begin
    if (rst) begin
      data_upper_pipe <= {(WIDTH-16){1'b0}};
      subtractor_in_b_pipe <= 8'b0;
      valid_pipe <= 1'b0;
    end else begin
      data_upper_pipe <= data_in[WIDTH-1:16];
      subtractor_in_b_pipe <= subtractor_in_b;
      valid_pipe <= valid_in;
    end
  end
  
  // 第二级流水线：最终输出
  always @(posedge clk) begin
    if (rst) begin
      data_out <= {WIDTH{1'b0}};
      valid_out <= 1'b0;
    end else begin
      // Replace the lower 8 bits with subtraction result
      data_out <= {data_upper_pipe, subtractor_in_b_pipe, subtractor_result};
      valid_out <= valid_pipe;
    end
  end
endmodule

// Two's complement subtractor module (8-bit)
module twos_complement_subtractor (
  input [7:0] a,
  input [7:0] b,
  output [7:0] result
);
  // 拆分为两个流水线阶段以减少关键路径
  reg [7:0] b_negated;
  reg [7:0] a_pipe;
  wire [7:0] b_complement;
  wire carry;
  
  // 第一级：取反
  assign b_complement = ~b + 8'b1;
  
  // 第二级：加法
  assign {carry, result} = {1'b0, a} + {1'b0, b_complement};
endmodule