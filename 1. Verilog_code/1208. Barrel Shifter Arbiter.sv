module barrel_arbiter #(parameter CLIENTS=8) (
  input clk, rst,
  input [CLIENTS-1:0] requests,
  output reg [CLIENTS-1:0] grants,
  output reg [$clog2(CLIENTS)-1:0] position
);
  reg [CLIENTS-1:0] rotated_req;
  reg [CLIENTS-1:0] rotated_grant;
  reg [$clog2(CLIENTS)-1:0] pos_next;
  integer i;
  
  always @(*) begin
    for (i = 0; i < CLIENTS; i = i + 1)
      rotated_req[i] = requests[(i + position) % CLIENTS];
    
    rotated_grant = 0;
    pos_next = position;
    
    if (rotated_req[0]) begin
      rotated_grant[0] = 1'b1;
      pos_next = (position + 1) % CLIENTS;
    end
    else if (|rotated_req) begin
      for (i = 1; i < CLIENTS; i = i + 1) begin
        if (rotated_req[i] && !rotated_grant) begin
          rotated_grant[i] = 1'b1;
          pos_next = (position + i + 1) % CLIENTS;
        end
      end
    end
    
    for (i = 0; i < CLIENTS; i = i + 1)
      grants[i] = rotated_grant[(CLIENTS - position + i) % CLIENTS];
  end
  
  always @(posedge clk) begin
    if (rst) position <= 0;
    else position <= pos_next;
  end
endmodule