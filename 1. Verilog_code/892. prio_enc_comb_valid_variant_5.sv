//SystemVerilog
// IEEE 1364-2005 Verilog standard
module prio_enc_comb_valid #(parameter W=4, A=2)(
  input [W-1:0] requests,
  output reg [A-1:0] encoded_addr,
  output reg valid
);
  // Lookup table for priority encoding
  reg [A-1:0] lut_addr [0:W-1];
  reg [W-1:0] lut_valid [0:W-1];
  
  // Initialize lookup tables
  initial begin
    // Address lookup table
    lut_addr[0] = 2'b00;
    lut_addr[1] = 2'b01;
    lut_addr[2] = 2'b10;
    lut_addr[3] = 2'b11;
    
    // Valid lookup table - one-hot encoding
    lut_valid[0] = 4'b0001;
    lut_valid[1] = 4'b0010;
    lut_valid[2] = 4'b0100;
    lut_valid[3] = 4'b1000;
  end
  
  // Priority encoding using lookup tables
  always @(*) begin
    encoded_addr = 0;
    valid = 0;
    
    // Use lookup tables for faster priority encoding
    if (requests[0]) begin
      encoded_addr = lut_addr[0];
      valid = 1;
    end
    else if (requests[1]) begin
      encoded_addr = lut_addr[1];
      valid = 1;
    end
    else if (requests[2]) begin
      encoded_addr = lut_addr[2];
      valid = 1;
    end
    else if (requests[3]) begin
      encoded_addr = lut_addr[3];
      valid = 1;
    end
  end
endmodule