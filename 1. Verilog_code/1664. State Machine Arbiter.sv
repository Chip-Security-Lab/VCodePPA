module fsm_arbiter(
  input wire clock, resetn,
  input wire [3:0] request,
  output reg [3:0] grant
);
  localparam IDLE = 2'b00, GRANT0 = 2'b01, 
             GRANT1 = 2'b10, GRANT2 = 2'b11;
  reg [1:0] state, next_state;
  
  always @(posedge clock or negedge resetn) begin
    if (!resetn) state <= IDLE;
    else state <= next_state;
  end
  
  always @(*) begin
    next_state = state;
    grant = 4'b0;
    case (state)
      IDLE: if (|request) next_state = GRANT0;
      GRANT0: begin grant = 4'b0001 & {4{request[0]}}; 
              if (!request[0]) next_state = GRANT1; end
      // More states would follow for complete FSM
    endcase
  end
endmodule