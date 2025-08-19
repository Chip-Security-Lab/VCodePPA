module sequence_detector(
    input clk,
    input reset,
    input data_in,
    output reg pattern_detected
);
    parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10;
    reg [1:0] current_state, next_state;
    
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= S0;
        else
            current_state <= next_state;
    end
    
    always @(*) begin
        case (current_state)
            S0: next_state = data_in ? S1 : S0;
            S1: next_state = data_in ? S1 : S2;
            S2: next_state = data_in ? S1 : S0;
            default: next_state = S0;
        endcase
    end
    
    always @(*) begin
        pattern_detected = (current_state == S2 && data_in == 1);
    end
endmodule