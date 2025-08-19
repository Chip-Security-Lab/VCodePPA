//SystemVerilog
module sequence_detector(
    input clk,
    input reset,
    input valid,
    input data_in,
    output reg ready,
    output reg pattern_detected
);
    parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10;
    reg [1:0] current_state, next_state;
    reg data_valid;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= S0;
            ready <= 1'b0;
            data_valid <= 1'b0;
        end else begin
            if (valid && ready) begin
                data_valid <= 1'b1;
                ready <= 1'b0;
            end else if (!valid) begin
                ready <= 1'b1;
                data_valid <= 1'b0;
            end
            current_state <= next_state;
        end
    end
    
    always @(*) begin
        case (current_state)
            S0: next_state = (data_valid && data_in) ? S1 : S0;
            S1: next_state = (data_valid && data_in) ? S1 : S2;
            S2: next_state = (data_valid && data_in) ? S1 : S0;
            default: next_state = S0;
        endcase
    end
    
    always @(*) begin
        pattern_detected = (current_state == S2 && data_valid && data_in == 1);
    end
endmodule