module distributed_priority_intr_ctrl(
  input clk, rst,
  input [15:0] req,
  output reg [3:0] id,
  output reg active
);
  wire [1:0] group_id;
  wire [3:0] group_req;
  wire [3:0] sub_id [0:3];
  wire [3:0] sub_valid;
  
  // Group-level priority detection
  assign group_req[0] = |req[3:0];
  assign group_req[1] = |req[7:4];
  assign group_req[2] = |req[11:8];
  assign group_req[3] = |req[15:12];
  
  // Sub-encoders
  assign sub_valid[0] = group_req[0];
  assign sub_id[0] = req[0] ? 4'd0 : (req[1] ? 4'd1 : (req[2] ? 4'd2 : 4'd3));
  
  assign sub_valid[1] = group_req[1];
  assign sub_id[1] = req[4] ? 4'd4 : (req[5] ? 4'd5 : (req[6] ? 4'd6 : 4'd7));
  
  assign sub_valid[2] = group_req[2];
  assign sub_id[2] = req[8] ? 4'd8 : (req[9] ? 4'd9 : (req[10] ? 4'd10 : 4'd11));
  
  assign sub_valid[3] = group_req[3];
  assign sub_id[3] = req[12] ? 4'd12 : (req[13] ? 4'd13 : (req[14] ? 4'd14 : 4'd15));
  
  // Group encoder
  assign group_id = group_req[0] ? 2'd0 : (group_req[1] ? 2'd1 : 
                   (group_req[2] ? 2'd2 : 2'd3));
  
  always @(posedge clk) begin
    if (rst) begin
      id <= 4'd0; active <= 1'b0;
    end else begin
      active <= |group_req;
      id <= sub_id[group_id];
    end
  end
endmodule