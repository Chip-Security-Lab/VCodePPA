//SystemVerilog
// Top-level module
module RD5 #(parameter W=8)(
  input clk,
  input rst,
  input en,
  input [W-1:0] din,
  output [W-1:0] dout
);
  // Internal connections
  wire [W-1:0] stage1_data;
  
  // First stage register
  Register_Stage #(
    .WIDTH(W)
  ) first_stage (
    .clk(clk),
    .rst(rst),
    .en(en),
    .data_in(din),
    .data_out(stage1_data)
  );
  
  // Second stage register
  Register_Stage #(
    .WIDTH(W)
  ) second_stage (
    .clk(clk),
    .rst(rst),
    .en(en),
    .data_in(stage1_data),
    .data_out(dout)
  );
endmodule

// Single register stage module
module Register_Stage #(parameter WIDTH=8)(
  input clk,
  input rst,
  input en,
  input [WIDTH-1:0] data_in,
  output reg [WIDTH-1:0] data_out
);
  // Reset has higher priority than enable
  always @(posedge clk) begin
    if (rst) begin
      data_out <= {WIDTH{1'b0}};
    end else if (en) begin
      data_out <= data_in;
    end
  end
endmodule