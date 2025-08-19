//SystemVerilog
// Top-level module
module reset_with_enable_priority #(parameter WIDTH = 4)(
  input wire clk,
  input wire rst,
  input wire en,
  output wire [WIDTH-1:0] data_out
);
  wire [WIDTH-1:0] internal_data;
  
  // Instantiate counter module
  counter_module #(
    .WIDTH(WIDTH)
  ) counter_inst (
    .clk(clk),
    .rst(rst),
    .en(en),
    .count_out(internal_data)
  );
  
  // Instantiate output register module
  output_register #(
    .WIDTH(WIDTH)
  ) output_reg_inst (
    .clk(clk),
    .data_in(internal_data),
    .data_out(data_out)
  );
  
endmodule

// Counter module for handling the counting logic
module counter_module #(parameter WIDTH = 4)(
  input wire clk,
  input wire rst,
  input wire en,
  output wire [WIDTH-1:0] count_out
);
  reg [WIDTH-1:0] count_reg;
  wire [WIDTH-1:0] next_count;
  
  // Move register downstream of combinational logic
  assign next_count = count_reg + 1'b1;
  assign count_out = count_reg;
  
  always @(posedge clk) begin
    if (rst)
      count_reg <= {WIDTH{1'b0}};
    else if (en)
      count_reg <= next_count;
  end
  
endmodule

// Output register module for registering the output
module output_register #(parameter WIDTH = 4)(
  input wire clk,
  input wire [WIDTH-1:0] data_in,
  output reg [WIDTH-1:0] data_out
);
  
  always @(posedge clk) begin
    data_out <= data_in;
  end
  
endmodule