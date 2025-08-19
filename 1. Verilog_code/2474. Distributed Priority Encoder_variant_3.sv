//SystemVerilog
module distributed_priority_intr_ctrl(
  input clk, rst,
  input [15:0] req_data,
  input req_valid,
  output reg req_ready,
  output reg [3:0] id,
  output reg id_valid,
  input id_ready
);
  wire [1:0] group_id;
  wire [3:0] group_req;
  wire [3:0] sub_id [0:3];
  wire [3:0] sub_valid;
  
  reg data_captured;
  reg [15:0] req;
  
  // Capture input data when valid and ready
  always @(posedge clk) begin
    if (rst) begin
      data_captured <= 1'b0;
      req <= 16'd0;
    end else if (req_valid && req_ready) begin
      req <= req_data;
      data_captured <= 1'b1;
    end else if (id_valid && id_ready) begin
      data_captured <= 1'b0;
    end
  end
  
  // Ready signal generation
  always @(posedge clk) begin
    if (rst) begin
      req_ready <= 1'b1;
    end else if (req_valid && req_ready) begin
      req_ready <= 1'b0;
    end else if (id_valid && id_ready) begin
      req_ready <= 1'b1;
    end
  end
  
  // Group-level priority detection
  assign group_req[0] = |req[3:0];
  assign group_req[1] = |req[7:4];
  assign group_req[2] = |req[11:8];
  assign group_req[3] = |req[15:12];
  
  // First pipeline stage: Calculate sub-level priority detection
  // Split the long combinational paths by adding pipeline registers
  
  // Sub-encoders intermediate signals for first level logic
  wire req0_n = ~req[0];
  wire req1_n = ~req[1];
  wire req2_n = ~req[2];
  wire req4_n = ~req[4];
  wire req5_n = ~req[5];
  wire req6_n = ~req[6];
  wire req8_n = ~req[8];
  wire req9_n = ~req[9];
  wire req10_n = ~req[10];
  wire req12_n = ~req[12];
  wire req13_n = ~req[13];
  wire req14_n = ~req[14];
  
  // Intermediate terms for sub_id calculations
  wire [3:0] sub0_term0, sub0_term1, sub0_term2, sub0_term3;
  wire [3:0] sub1_term0, sub1_term1, sub1_term2, sub1_term3;
  wire [3:0] sub2_term0, sub2_term1, sub2_term2, sub2_term3;
  wire [3:0] sub3_term0, sub3_term1, sub3_term2, sub3_term3;
  
  assign sub0_term0 = {4{req[0]}} & 4'd0;
  assign sub0_term1 = {4{req0_n & req[1]}} & 4'd1;
  assign sub0_term2 = {4{req0_n & req1_n & req[2]}} & 4'd2;
  assign sub0_term3 = {4{req0_n & req1_n & req2_n & req[3]}} & 4'd3;
  
  assign sub1_term0 = {4{req[4]}} & 4'd4;
  assign sub1_term1 = {4{req4_n & req[5]}} & 4'd5;
  assign sub1_term2 = {4{req4_n & req5_n & req[6]}} & 4'd6;
  assign sub1_term3 = {4{req4_n & req5_n & req6_n & req[7]}} & 4'd7;
  
  assign sub2_term0 = {4{req[8]}} & 4'd8;
  assign sub2_term1 = {4{req8_n & req[9]}} & 4'd9;
  assign sub2_term2 = {4{req8_n & req9_n & req[10]}} & 4'd10;
  assign sub2_term3 = {4{req8_n & req9_n & req10_n & req[11]}} & 4'd11;
  
  assign sub3_term0 = {4{req[12]}} & 4'd12;
  assign sub3_term1 = {4{req12_n & req[13]}} & 4'd13;
  assign sub3_term2 = {4{req12_n & req13_n & req[14]}} & 4'd14;
  assign sub3_term3 = {4{req12_n & req13_n & req14_n & req[15]}} & 4'd15;
  
  // Pipeline registers for sub-level priority calculations
  reg [3:0] sub_id_reg [0:3];
  reg [3:0] sub_valid_reg;
  reg [3:0] group_req_reg;
  reg data_captured_pipe;
  
  always @(posedge clk) begin
    if (rst) begin
      sub_id_reg[0] <= 4'd0;
      sub_id_reg[1] <= 4'd0;
      sub_id_reg[2] <= 4'd0;
      sub_id_reg[3] <= 4'd0;
      sub_valid_reg <= 4'd0;
      group_req_reg <= 4'd0;
      data_captured_pipe <= 1'b0;
    end else begin
      // Register the sub-priority encoders' outputs
      sub_id_reg[0] <= sub0_term0 | sub0_term1 | sub0_term2 | sub0_term3;
      sub_id_reg[1] <= sub1_term0 | sub1_term1 | sub1_term2 | sub1_term3;
      sub_id_reg[2] <= sub2_term0 | sub2_term1 | sub2_term2 | sub2_term3;
      sub_id_reg[3] <= sub3_term0 | sub3_term1 | sub3_term2 | sub3_term3;
      
      // Register group request signals
      sub_valid_reg[0] <= group_req[0];
      sub_valid_reg[1] <= group_req[1];
      sub_valid_reg[2] <= group_req[2];
      sub_valid_reg[3] <= group_req[3];
      group_req_reg <= group_req;
      
      // Register data_captured for alignment
      data_captured_pipe <= data_captured;
    end
  end
  
  // Second pipeline stage: Group encoder
  // Intermediate signals for group encoder
  wire group_req0_n = ~group_req_reg[0];
  wire group_req1_n = ~group_req_reg[1];
  wire group_req2_n = ~group_req_reg[2];
  
  wire [1:0] group_term0, group_term1, group_term2, group_term3;
  
  assign group_term0 = {2{group_req_reg[0]}} & 2'd0;
  assign group_term1 = {2{group_req0_n & group_req_reg[1]}} & 2'd1;
  assign group_term2 = {2{group_req0_n & group_req1_n & group_req_reg[2]}} & 2'd2;
  assign group_term3 = {2{group_req0_n & group_req1_n & group_req2_n & group_req_reg[3]}} & 2'd3;
  
  // Compute group_id from pipelined signals
  assign group_id = group_term0 | group_term1 | group_term2 | group_term3;
  
  // Compute sub_id and sub_valid from pipelined signals
  assign sub_id[0] = sub_id_reg[0];
  assign sub_id[1] = sub_id_reg[1];
  assign sub_id[2] = sub_id_reg[2];
  assign sub_id[3] = sub_id_reg[3];
  assign sub_valid = sub_valid_reg;
  
  // Final output selection using pipelined signals
  wire [3:0] selected_id;
  wire group_valid = |group_req_reg;
  
  // Multiplexer logic for final ID selection
  wire [3:0] mux_out_0 = {4{group_id == 2'd0}} & sub_id[0];
  wire [3:0] mux_out_1 = {4{group_id == 2'd1}} & sub_id[1];
  wire [3:0] mux_out_2 = {4{group_id == 2'd2}} & sub_id[2];
  wire [3:0] mux_out_3 = {4{group_id == 2'd3}} & sub_id[3];
  
  assign selected_id = mux_out_0 | mux_out_1 | mux_out_2 | mux_out_3;
  
  // Output ID and valid logic - adjusted for pipeline delay
  always @(posedge clk) begin
    if (rst) begin
      id <= 4'd0;
      id_valid <= 1'b0;
    end else if (data_captured_pipe && group_valid && !id_valid) begin
      id <= selected_id;
      id_valid <= 1'b1;
    end else if (id_valid && id_ready) begin
      id_valid <= 1'b0;
    end
  end
endmodule