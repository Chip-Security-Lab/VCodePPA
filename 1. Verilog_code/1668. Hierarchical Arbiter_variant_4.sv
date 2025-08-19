//SystemVerilog
module hierarchical_arbiter(
  input clock, reset,
  input [7:0] requests,
  output reg [7:0] grants
);
  // Buffer registers for high fanout signals
  reg [7:0] requests_buf;
  reg [1:0] level1_req_buf;
  reg [1:0] level1_grant_buf;
  reg [1:0] level1_grant;
  wire [1:0] level1_req;
  
  // Buffer for requests
  always @(posedge clock) begin
    if (reset) begin
      requests_buf <= 8'b00000000;
    end else begin
      requests_buf <= requests;
    end
  end
  
  // Level 1 request calculation with buffering
  assign level1_req[0] = |requests_buf[3:0];
  assign level1_req[1] = |requests_buf[7:4];
  
  // Buffer for level1_req
  always @(posedge clock) begin
    if (reset) begin
      level1_req_buf <= 2'b00;
    end else begin
      level1_req_buf <= level1_req;
    end
  end
  
  // Level 1 arbitration with buffering
  always @(posedge clock) begin
    if (reset) begin
      level1_grant_buf <= 2'b00;
      level1_grant <= 2'b00;
    end else begin
      level1_grant_buf <= level1_req_buf & ~(level1_req_buf - 1);
      level1_grant <= level1_grant_buf;
    end
  end
  
  // Level 2 arbitration with buffered signals
  always @(posedge clock) begin
    if (reset) begin
      grants <= 8'b00000000;
    end else begin
      grants <= 8'b00000000;
      if (level1_grant[0] && requests_buf[0]) grants[0] <= 1'b1;
      else if (level1_grant[0] && requests_buf[1]) grants[1] <= 1'b1;
      else if (level1_grant[0] && requests_buf[2]) grants[2] <= 1'b1;
      else if (level1_grant[0] && requests_buf[3]) grants[3] <= 1'b1;
      else if (level1_grant[1] && requests_buf[4]) grants[4] <= 1'b1;
      else if (level1_grant[1] && requests_buf[5]) grants[5] <= 1'b1;
      else if (level1_grant[1] && requests_buf[6]) grants[6] <= 1'b1;
      else if (level1_grant[1] && requests_buf[7]) grants[7] <= 1'b1;
    end
  end
endmodule