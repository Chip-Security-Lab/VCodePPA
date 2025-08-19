module pipelined_intr_ctrl(
  input clk, rst_n,
  input [15:0] intr_req,
  output reg [3:0] intr_id,
  output reg valid
);
  // Pipeline registers
  reg [15:0] stage1_req;
  reg [3:0] stage2_id;
  reg stage2_valid;
  reg [3:0] highest_pri_id;
  reg req_valid;
  
  // Pipeline stage 1: detect and latch requests
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      stage1_req <= 16'h0;
    else
      stage1_req <= intr_req;
  end
  
  // Pipeline stage 2: encode priority
  always @(*) begin
    req_valid = |stage1_req;
    casez (stage1_req)
      16'b1???????????????: highest_pri_id = 4'd15;
      16'b01??????????????: highest_pri_id = 4'd14;
      16'b001?????????????: highest_pri_id = 4'd13;
      16'b0001????????????: highest_pri_id = 4'd12;
      16'b00001???????????: highest_pri_id = 4'd11;
      16'b000001??????????: highest_pri_id = 4'd10;
      16'b0000001?????????: highest_pri_id = 4'd9;
      16'b00000001????????: highest_pri_id = 4'd8;
      16'b000000001???????: highest_pri_id = 4'd7;
      16'b0000000001??????: highest_pri_id = 4'd6;
      16'b00000000001?????: highest_pri_id = 4'd5;
      16'b000000000001????: highest_pri_id = 4'd4;
      16'b0000000000001???: highest_pri_id = 4'd3;
      16'b00000000000001??: highest_pri_id = 4'd2;
      16'b000000000000001?: highest_pri_id = 4'd1;
      16'b0000000000000001: highest_pri_id = 4'd0;
      default: highest_pri_id = 4'd0;
    endcase
  end
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage2_id <= 4'h0;
      stage2_valid <= 1'b0;
    end else begin
      stage2_id <= highest_pri_id;
      stage2_valid <= req_valid;
    end
  end
  
  // Pipeline stage 3: output
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 4'h0;
      valid <= 1'b0;
    end else begin
      intr_id <= stage2_id;
      valid <= stage2_valid;
    end
  end
endmodule