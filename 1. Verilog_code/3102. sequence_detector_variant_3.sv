//SystemVerilog
module sequence_detector(
    input clk,
    input reset,
    input data_in,
    output reg pattern_detected
);
    parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10;
    reg [1:0] current_state, next_state;
    reg [1:0] state_stage1, state_stage2;
    reg data_in_stage1, data_in_stage2;
    
    // Stage 1: Input sampling and state transition
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage1 <= S0;
            data_in_stage1 <= 1'b0;
        end else begin
            state_stage1 <= current_state;
            data_in_stage1 <= data_in;
        end
    end
    
    // Stage 2: Next state computation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage2 <= S0;
            data_in_stage2 <= 1'b0;
        end else begin
            state_stage2 <= state_stage1;
            data_in_stage2 <= data_in_stage1;
        end
    end
    
    // Stage 3: State update and pattern detection
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= S0;
            pattern_detected <= 1'b0;
        end else begin
            current_state <= next_state;
            pattern_detected <= state_stage2[1] & ~state_stage2[0] & data_in_stage2;
        end
    end
    
    always @(*) begin
        case (state_stage1)
            S0: begin
                next_state[1] = 1'b0;
                next_state[0] = data_in_stage1;
            end
            S1: begin
                next_state[1] = ~data_in_stage1;
                next_state[0] = data_in_stage1;
            end
            S2: begin
                next_state[1] = 1'b0;
                next_state[0] = data_in_stage1;
            end
            default: next_state = S0;
        endcase
    end
endmodule