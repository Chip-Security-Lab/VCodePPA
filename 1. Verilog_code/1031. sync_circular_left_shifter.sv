module sync_circular_left_shifter #(parameter WIDTH = 8) (
  input clk,
  input [2:0] shift_amt,
  input [WIDTH-1:0] data_in,
  output reg [WIDTH-1:0] data_out
);
  always @(posedge clk) begin
    // Rotation left by variable amount using concatenation
    case(shift_amt)
      3'd1: data_out <= {data_in[WIDTH-2:0], data_in[WIDTH-1]};
      3'd2: data_out <= {data_in[WIDTH-3:0], data_in[WIDTH-1:WIDTH-2]};
      3'd3: data_out <= {data_in[WIDTH-4:0], data_in[WIDTH-1:WIDTH-3]};
      3'd4: data_out <= {data_in[WIDTH-5:0], data_in[WIDTH-1:WIDTH-4]};
      default: data_out <= data_in;
    endcase
  end
endmodule