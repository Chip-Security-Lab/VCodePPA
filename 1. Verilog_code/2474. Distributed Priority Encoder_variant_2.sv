//SystemVerilog
//IEEE 1364-2005 Verilog
module distributed_priority_intr_ctrl(
  input clk, rst,
  input [15:0] req,
  output reg [3:0] id,
  output reg active
);
  // Pre-computed group requests to reduce logic depth
  wire req_g0 = |req[3:0];
  wire req_g1 = |req[7:4];
  wire req_g2 = |req[11:8];
  wire req_g3 = |req[15:12];
  wire [3:0] group_req = {req_g3, req_g2, req_g1, req_g0};
  
  // Flattened priority encoding for group level
  wire [1:0] group_id;
  assign group_id[0] = ~req_g0 & req_g1 | ~req_g0 & ~req_g2 & req_g3;
  assign group_id[1] = ~req_g0 & ~req_g1 & (req_g2 | req_g3);
  
  // Optimized sub-encoders with pre-computed masks
  reg [3:0] sub_id;
  
  // Efficient sub-group selection using multiplexing approach
  always @(*) begin
    case (group_id)
      2'b00: begin // Group 0 (bits 3:0)
        if (req[0])      sub_id = 4'd0;
        else if (req[1]) sub_id = 4'd1;
        else if (req[2]) sub_id = 4'd2;
        else             sub_id = 4'd3; // req[3] must be active if we're here
      end
      
      2'b01: begin // Group 1 (bits 7:4)
        if (req[4])      sub_id = 4'd4;
        else if (req[5]) sub_id = 4'd5;
        else if (req[6]) sub_id = 4'd6;
        else             sub_id = 4'd7; // req[7] must be active if we're here
      end
      
      2'b10: begin // Group 2 (bits 11:8)
        if (req[8])       sub_id = 4'd8;
        else if (req[9])  sub_id = 4'd9;
        else if (req[10]) sub_id = 4'd10;
        else              sub_id = 4'd11; // req[11] must be active if we're here
      end
      
      2'b11: begin // Group 3 (bits 15:12)
        if (req[12])      sub_id = 4'd12;
        else if (req[13]) sub_id = 4'd13;
        else if (req[14]) sub_id = 4'd14;
        else              sub_id = 4'd15; // req[15] must be active if we're here
      end
    endcase
  end
  
  // Compute any_req signal with balanced tree structure
  wire any_req = (req_g0 | req_g1) | (req_g2 | req_g3);
  
  // Sequential logic for output registers
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      id <= 4'd0; 
      active <= 1'b0;
    end else begin
      active <= any_req;
      id <= sub_id;
    end
  end
endmodule