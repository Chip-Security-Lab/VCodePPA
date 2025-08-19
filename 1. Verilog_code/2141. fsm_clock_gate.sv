module fsm_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire start,
    input  wire done,
    output wire clk_out
);
    localparam IDLE = 1'b0, ACTIVE = 1'b1;
    reg state, next_state;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    always @(*) begin
        case (state)
            IDLE:   next_state = start ? ACTIVE : IDLE;
            ACTIVE: next_state = done ? IDLE : ACTIVE;
        endcase
    end
    
    assign clk_out = clk_in & (state == ACTIVE);
endmodule