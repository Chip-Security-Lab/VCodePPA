module external_reset_validator (
  input wire clk,
  input wire ext_reset,
  input wire validation_en,
  output reg valid_reset,
  output reg invalid_reset
);
  reg [1:0] ext_reset_sync;
  
  always @(posedge clk) begin
    ext_reset_sync <= {ext_reset_sync[0], ext_reset};
    
    valid_reset <= ext_reset_sync[1] && validation_en;
    invalid_reset <= ext_reset_sync[1] && !validation_en;
  end
endmodule
