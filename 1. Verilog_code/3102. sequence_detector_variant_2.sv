//SystemVerilog
module sequence_detector(
    input clk,
    input reset,
    input req,
    output reg ack,
    input data_in,
    output reg pattern_detected
);
    parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10;
    reg [1:0] current_state, next_state;
    reg req_reg;
    
    // Simplified multiplier implementation
    wire [1:0] mult_result;
    assign mult_result[0] = data_in & req;
    assign mult_result[1] = data_in ^ req;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= S0;
            req_reg <= 1'b0;
        end else begin
            current_state <= next_state;
            req_reg <= mult_result[0];
        end
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
        ack = mult_result[1];
    end
endmodule