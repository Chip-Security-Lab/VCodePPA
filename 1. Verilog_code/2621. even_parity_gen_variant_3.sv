//SystemVerilog
module parity_calculator #(
  parameter WIDTH = 8
)(
  input wire clk,
  input wire rst_n,
  input wire [WIDTH-1:0] data,
  output reg parity
);

  // Pipeline stage 1: Data input register
  reg [WIDTH-1:0] data_reg;
  
  // Pipeline stage 2: Parity calculation
  wire parity_calc;
  assign parity_calc = ^data_reg;
  
  // Pipeline stage 3: Output register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_reg <= {WIDTH{1'b0}};
      parity <= 1'b0;
    end else begin
      data_reg <= data;
      parity <= parity_calc;
    end
  end

endmodule

module even_parity_gen #(
  parameter DATA_WIDTH = 8
)(
  input wire clk,
  input wire rst_n,
  input wire [DATA_WIDTH-1:0] data_in,
  output wire parity_out
);

  parity_calculator #(
    .WIDTH(DATA_WIDTH)
  ) parity_calc (
    .clk(clk),
    .rst_n(rst_n),
    .data(data_in),
    .parity(parity_out)
  );

endmodule