module fsm_divider (
    input clk_input, reset,
    output clk_output
);
    reg [1:0] state, next_state;
    localparam S0 = 2'b00, S1 = 2'b01, 
               S2 = 2'b10, S3 = 2'b11;
               
    always @(posedge clk_input) begin
        if (reset) state <= S0;
        else state <= next_state;
    end
    
    always @(*) begin
        case(state)
            S0: next_state = S1;
            S1: next_state = S2;
            S2: next_state = S3;
            S3: next_state = S0;
            default: next_state = S0;
        endcase
    end
    
    assign clk_output = (state == S0 || state == S1);
endmodule