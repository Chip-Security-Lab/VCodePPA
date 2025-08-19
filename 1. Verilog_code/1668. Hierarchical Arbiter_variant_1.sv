//SystemVerilog
module hierarchical_arbiter(
  input clock, reset,
  input [7:0] requests,
  output reg [7:0] grants
);

  // Buffer registers for high fanout signals
  reg [7:0] requests_buf1;
  reg [7:0] requests_buf2;
  wire [1:0] level1_req;
  reg [1:0] level1_req_buf1;
  reg [1:0] level1_req_buf2;
  reg [1:0] level1_grant;
  reg [1:0] level1_grant_buf;
  
  // First level buffering with two stages
  always @(posedge clock) begin
    if (reset) begin
      requests_buf1 <= 8'b0;
      requests_buf2 <= 8'b0;
    end else begin
      requests_buf1 <= requests;
      requests_buf2 <= requests_buf1;
    end
  end
  
  // Second level buffering with two stages
  always @(posedge clock) begin
    if (reset) begin
      level1_req_buf1 <= 2'b0;
      level1_req_buf2 <= 2'b0;
    end else begin
      level1_req_buf1 <= level1_req;
      level1_req_buf2 <= level1_req_buf1;
    end
  end

  // Grant buffering
  always @(posedge clock) begin
    if (reset) begin
      level1_grant <= 2'b00;
      level1_grant_buf <= 2'b00;
    end else begin
      level1_grant <= level1_req_buf2 & ~(level1_req_buf2 - 1);
      level1_grant_buf <= level1_grant;
    end
  end
  
  assign level1_req[0] = |requests_buf2[3:0];
  assign level1_req[1] = |requests_buf2[7:4];
  
  always @(posedge clock) begin
    if (reset) begin
      grants <= 8'b00000000;
    end else begin
      grants <= 8'b00000000;
      if (level1_grant_buf[0]) grants[3:0] <= requests_buf2[3:0];
      if (level1_grant_buf[1]) grants[7:4] <= requests_buf2[7:4];
    end
  end

endmodule