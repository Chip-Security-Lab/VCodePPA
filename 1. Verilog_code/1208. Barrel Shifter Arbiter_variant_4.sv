//SystemVerilog
module barrel_arbiter #(parameter CLIENTS=8) (
  input clk, rst,
  input [CLIENTS-1:0] requests,
  output reg [CLIENTS-1:0] grants,
  output reg [$clog2(CLIENTS)-1:0] position
);
  // High fanout signal buffers
  reg [$clog2(CLIENTS)-1:0] position_buf1, position_buf2;
  reg [CLIENTS-1:0] rotated_req;
  reg [CLIENTS-1:0] rotated_req_buf1, rotated_req_buf2;
  reg [CLIENTS-1:0] rotated_grant;
  reg [CLIENTS-1:0] rotated_grant_buf1, rotated_grant_buf2;
  reg [$clog2(CLIENTS)-1:0] pos_next;
  reg [$clog2(CLIENTS)-1:0] pos_next_buf;
  
  // Integer counter with buffered versions for different operations
  integer i;
  reg [31:0] i_buf1, i_buf2, i_buf3;
  
  // Skip carry adder signals
  wire [31:0] add_result_pos_next;
  wire [31:0] add_result_rotation;
  wire c_out;
  
  // Register buffers for high fanout signals at clock edge
  always @(posedge clk) begin
    if (rst) begin
      position_buf1 <= 0;
      position_buf2 <= 0;
    end
    else begin
      position_buf1 <= position;
      position_buf2 <= position;
    end
    
    rotated_req_buf1 <= rotated_req;
    rotated_req_buf2 <= rotated_req;
    
    rotated_grant_buf1 <= rotated_grant;
    rotated_grant_buf2 <= rotated_grant;
    
    pos_next_buf <= pos_next;
  end
  
  // Stage 1: Calculate rotated requests with fanout reduction
  always @(*) begin
    for (i = 0; i < CLIENTS; i = i + 1) begin
      i_buf1 = i; // Buffer i for this operation
      rotated_req[i] = requests[(skip_carry_mod(i_buf1 + position_buf1, CLIENTS))];
    end
  end
  
  // Stage 2: Calculate rotated grants and next position
  always @(*) begin
    rotated_grant = 0;
    pos_next = position;
    
    if (rotated_req_buf1[0]) begin
      rotated_grant[0] = 1'b1;
      pos_next = skip_carry_mod(position_buf1 + 1, CLIENTS);
    end
    else if (|rotated_req_buf1) begin
      for (i = 1; i < CLIENTS; i = i + 1) begin
        i_buf2 = i; // Buffer i for this operation
        if (rotated_req_buf1[i_buf2] && !rotated_grant) begin
          rotated_grant[i_buf2] = 1'b1;
          pos_next = skip_carry_mod(position_buf1 + i_buf2 + 1, CLIENTS);
        end
      end
    end
  end
  
  // Stage 3: Calculate final grants with fanout reduction
  always @(*) begin
    for (i = 0; i < CLIENTS; i = i + 1) begin
      i_buf3 = i; // Buffer i for this operation
      grants[i_buf3] = rotated_grant_buf2[(skip_carry_mod(CLIENTS - position_buf2 + i_buf3, CLIENTS))];
    end
  end
  
  // Update position register
  always @(posedge clk) begin
    if (rst) position <= 0;
    else position <= pos_next_buf;
  end
  
  // Function to compute modulo using skip carry approach
  function [31:0] skip_carry_mod;
    input [31:0] value;
    input [31:0] modulus;
    begin
      if (value < modulus)
        skip_carry_mod = value;
      else
        skip_carry_mod = value - modulus;
    end
  endfunction
  
endmodule