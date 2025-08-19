//SystemVerilog
module barrel_arbiter #(parameter CLIENTS=8) (
  input wire clk, rst,
  input wire [CLIENTS-1:0] requests,
  output reg [CLIENTS-1:0] grants,
  output reg [$clog2(CLIENTS)-1:0] position
);
  // Buffered position signals for fanout reduction
  reg [$clog2(CLIENTS)-1:0] position_buf1, position_buf2;
  
  reg [CLIENTS-1:0] rotated_req;
  reg [CLIENTS-1:0] rotated_req_buf1, rotated_req_buf2;
  
  reg [CLIENTS-1:0] rotated_grant;
  reg [CLIENTS-1:0] rotated_grant_buf1, rotated_grant_buf2;
  
  reg [$clog2(CLIENTS)-1:0] pos_next;
  reg [$clog2(CLIENTS)-1:0] pos_next_buf;
  
  // Buffer registers for high fan-out index variable
  reg [$clog2(CLIENTS):0] i_buf1, i_buf2;
  
  integer i;
  
  // Buffer position value at clock edge for fanout reduction
  always @(posedge clk) begin
    if (rst) begin
      position_buf1 <= 0;
      position_buf2 <= 0;
    end 
    else begin
      position_buf1 <= position;
      position_buf2 <= position;
    end
  end
  
  // Create rotated request vector with buffered position
  always @(*) begin
    for (i = 0; i < CLIENTS; i = i + 1) begin
      i_buf1 = i; // Buffer index to reduce fanout
      rotated_req[i] = requests[(i_buf1 + position_buf1) % CLIENTS];
    end
    
    // Buffer rotated request for fanout reduction
    rotated_req_buf1 = rotated_req;
    rotated_req_buf2 = rotated_req;
    
    rotated_grant = 0;
    pos_next = position;
    
    if (rotated_req_buf1[0]) begin
      rotated_grant[0] = 1'b1;
      pos_next = (position_buf1 + 1) % CLIENTS;
    end
    else if (|rotated_req_buf1) begin
      for (i = 1; i < CLIENTS; i = i + 1) begin
        i_buf2 = i; // Buffer index to reduce fanout
        if (rotated_req_buf2[i_buf2] && !rotated_grant) begin
          rotated_grant[i_buf2] = 1'b1;
          pos_next = (position_buf2 + i_buf2 + 1) % CLIENTS;
        end
      end
    end
    
    // Buffer pos_next to reduce fanout
    pos_next_buf = pos_next;
    
    // Buffer rotated grant for fanout reduction
    rotated_grant_buf1 = rotated_grant;
    rotated_grant_buf2 = rotated_grant;
    
    for (i = 0; i < CLIENTS; i = i + 1) begin
      i_buf1 = i; // Buffer index to reduce fanout
      grants[i] = rotated_grant_buf1[(CLIENTS - position_buf2 + i_buf1) % CLIENTS];
    end
  end
  
  // Register for position update with reduced fanout
  always @(posedge clk) begin
    if (rst) position <= 0;
    else position <= pos_next_buf;
  end
endmodule