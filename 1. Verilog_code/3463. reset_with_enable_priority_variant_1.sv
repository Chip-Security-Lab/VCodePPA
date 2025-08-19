//SystemVerilog
module reset_with_enable_priority #(parameter WIDTH = 4)(
  input clk, rst, en,
  output reg [WIDTH-1:0] data_out
);
  reg [WIDTH-1:0] internal_data;
  
  always @(posedge clk) begin
    case ({rst, en})
      2'b10, 2'b11: internal_data <= {WIDTH{1'b0}}; // rst=1 has priority
      2'b01:        internal_data <= internal_data + 1; // en=1, rst=0
      2'b00:        internal_data <= internal_data; // no change
    endcase
    
    data_out <= internal_data;
  end
endmodule