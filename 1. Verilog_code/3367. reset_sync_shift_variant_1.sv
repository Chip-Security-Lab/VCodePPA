//SystemVerilog
// Top level module
module reset_sync_shift #(
  parameter DEPTH = 3
) (
  input  wire clk,
  input  wire rst_n,
  output wire sync_out
);
  // Internal signal for connecting shift register output to sync logic
  wire [DEPTH-1:0] shift_reg_value;

  // Instantiate shift register submodule
  shift_register #(
    .WIDTH(DEPTH)
  ) u_shift_register (
    .clk       (clk),
    .rst_n     (rst_n),
    .shift_in  (1'b1),
    .reg_out   (shift_reg_value)
  );

  // Instantiate output logic submodule  
  sync_output_logic #(
    .DEPTH(DEPTH)
  ) u_sync_output_logic (
    .shift_reg_value (shift_reg_value),
    .sync_out        (sync_out)
  );

endmodule

// Shift register submodule
module shift_register #(
  parameter WIDTH = 3
) (
  input  wire clk,
  input  wire rst_n,
  input  wire shift_in,
  output reg [WIDTH-1:0] reg_out
);
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      reg_out <= {WIDTH{1'b0}};
    else
      reg_out <= {reg_out[WIDTH-2:0], shift_in};
  end

endmodule

// Output logic submodule
module sync_output_logic #(
  parameter DEPTH = 3
) (
  input  wire [DEPTH-1:0] shift_reg_value,
  output wire sync_out
);
  
  assign sync_out = shift_reg_value[DEPTH-1];

endmodule