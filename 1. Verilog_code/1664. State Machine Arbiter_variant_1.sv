//SystemVerilog
module fsm_arbiter(
  input wire clock, resetn,
  input wire [3:0] request,
  output reg [3:0] grant
);
  localparam IDLE = 2'b00, GRANT0 = 2'b01, 
             GRANT1 = 2'b10, GRANT2 = 2'b11;
  reg [1:0] state, next_state;
  
  always @(posedge clock or negedge resetn)
    if (!resetn) state <= IDLE;
    else state <= next_state;
  
  always @(*) begin
    next_state = state;
    grant = 4'b0;
    
    case (state)
      IDLE:    next_state = (request != 4'b0) ? GRANT0 : IDLE;
      GRANT0:  begin 
                grant = {4{request[0]}} & 4'b0001;
                next_state = (request[0]) ? GRANT0 : GRANT1;
               end
      GRANT1:  begin
                grant = {4{request[1]}} & 4'b0010;
                next_state = (request[1]) ? GRANT1 : GRANT2;
               end
      GRANT2:  begin
                grant = {4{request[2]}} & 4'b0100;
                next_state = (request[2]) ? GRANT2 : IDLE;
               end
      default: next_state = IDLE;
    endcase
  end
endmodule