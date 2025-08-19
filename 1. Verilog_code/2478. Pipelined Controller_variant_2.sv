//SystemVerilog
module pipelined_intr_ctrl(
  input clk, rst_n,
  input [15:0] intr_req,
  input ack,           // Changed from ready to ack signal
  output reg [3:0] intr_id,
  output reg req       // Changed from valid to req signal
);
  // Pipeline registers
  reg [15:0] stage1_req;
  reg [3:0] stage2_id;
  reg stage2_req;
  reg [3:0] highest_pri_id;
  reg req_valid;
  reg handshake_complete;
  
  // Pipeline stage 1: detect and latch requests
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      stage1_req <= 16'h0;
    else if (!req || (req && ack))
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
  
  // Record handshake completion status
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      handshake_complete <= 1'b0;
    else
      handshake_complete <= req && ack;
  end
  
  // Pipeline stage 2: latch priority encoder output
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage2_id <= 4'h0;
      stage2_req <= 1'b0;
    end else if (!stage2_req || handshake_complete) begin
      stage2_id <= highest_pri_id;
      stage2_req <= req_valid;
    end
  end
  
  // Pipeline stage 3: output with req-ack handshake
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 4'h0;
      req <= 1'b0;
    end else if (!req || ack) begin
      // Only update output when current data is acknowledged or no valid request
      intr_id <= stage2_id;
      req <= stage2_req;
    end
  end
endmodule