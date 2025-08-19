//SystemVerilog
module seq_detector_0110(
    input wire clk, rst_n, x,
    output reg z
);
    parameter S0=2'b00, S1=2'b01, S2=2'b10, S3=2'b11;
    reg [1:0] state, next_state;
    
    // Optimized state transition logic using explicit multiplexers
    wire [1:0] state_transition [3:0];
    
    // State transition multiplexers
    assign state_transition[0] = x ? S1 : S0;  // S0 transitions
    assign state_transition[1] = x ? S1 : S2;  // S1 transitions
    assign state_transition[2] = x ? S3 : S0;  // S2 transitions
    assign state_transition[3] = x ? S1 : S2;  // S3 transitions
    
    // State register
    always @(posedge clk or negedge rst_n)
        if (!rst_n) state <= S0;
        else state <= next_state;
    
    // Next state logic using explicit multiplexer
    always @(*) begin
        case (state)
            S0: next_state = state_transition[0];
            S1: next_state = state_transition[1];
            S2: next_state = state_transition[2];
            S3: next_state = state_transition[3];
            default: next_state = S0;
        endcase
        
        // Output logic using explicit AND gate
        z = (state == S3) & (~x);
    end
endmodule