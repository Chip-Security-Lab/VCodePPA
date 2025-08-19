//SystemVerilog
module sequence_detector(
    input clk,
    input reset,
    input data_in,
    output reg pattern_detected
);
    parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10;
    
    // Pipeline stage 1 registers
    reg [1:0] current_state_stage1;
    reg data_in_stage1;
    
    // Pipeline stage 2 registers
    reg [1:0] current_state_stage2;
    reg data_in_stage2;
    reg [1:0] next_state_stage2;
    
    // Pipeline stage 3 registers
    reg [1:0] current_state_stage3;
    reg data_in_stage3;
    reg pattern_detected_stage3;
    
    // Stage 1: Input sampling and state update
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state_stage1 <= S0;
            data_in_stage1 <= 1'b0;
        end else begin
            current_state_stage1 <= current_state_stage3;
            data_in_stage1 <= data_in;
        end
    end
    
    // Stage 2: Next state computation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state_stage2 <= S0;
            data_in_stage2 <= 1'b0;
            next_state_stage2 <= S0;
        end else begin
            current_state_stage2 <= current_state_stage1;
            data_in_stage2 <= data_in_stage1;
            next_state_stage2 <= (current_state_stage1 == S0) ? (data_in_stage1 ? S1 : S0) :
                                (current_state_stage1 == S1) ? (data_in_stage1 ? S1 : S2) :
                                (current_state_stage1 == S2) ? (data_in_stage1 ? S1 : S0) : S0;
        end
    end
    
    // Stage 3: State update and output computation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state_stage3 <= S0;
            data_in_stage3 <= 1'b0;
            pattern_detected_stage3 <= 1'b0;
        end else begin
            current_state_stage3 <= next_state_stage2;
            data_in_stage3 <= data_in_stage2;
            pattern_detected_stage3 <= (current_state_stage2 == S2 && data_in_stage2 == 1);
        end
    end
    
    // Output register
    always @(posedge clk or posedge reset) begin
        if (reset)
            pattern_detected <= 1'b0;
        else
            pattern_detected <= pattern_detected_stage3;
    end
endmodule