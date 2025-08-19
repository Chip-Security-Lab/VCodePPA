//SystemVerilog
module DebounceFSM #(
    parameter DEBOUNCE_MS = 20,
    parameter CLK_FREQ = 50_000_000
)(
    input clk, rst_n,
    input key_raw,
    output reg key_stable,
    output reg key_valid
);
    localparam COUNTER_MAX = (CLK_FREQ/1000)*DEBOUNCE_MS;
    localparam IDLE = 1'b0, DEBOUNCE = 1'b1;
    
    // Pipeline stage 1 registers
    reg current_state_stage1, next_state_stage1;
    reg [31:0] debounce_counter_stage1;
    reg key_sampled_stage1;
    reg key_raw_stage1;
    
    // Pipeline stage 2 registers
    reg current_state_stage2, next_state_stage2;
    reg [31:0] debounce_counter_stage2;
    reg key_sampled_stage2;
    reg key_stable_stage2;
    reg key_valid_stage2;
    
    // Pipeline stage 3 registers
    reg key_stable_stage3;
    reg key_valid_stage3;

    // Stage 1: Input sampling and state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_stage1 <= IDLE;
            debounce_counter_stage1 <= 0;
            key_sampled_stage1 <= 1'b1;
            key_raw_stage1 <= 1'b1;
        end else begin
            current_state_stage1 <= next_state_stage1;
            key_raw_stage1 <= key_raw;
            
            if (current_state_stage1 == DEBOUNCE) begin
                debounce_counter_stage1 <= debounce_counter_stage1 + 1;
            end else begin
                debounce_counter_stage1 <= 0;
                key_sampled_stage1 <= key_raw;
            end
        end
    end

    // Stage 2: Counter comparison and state update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_stage2 <= IDLE;
            debounce_counter_stage2 <= 0;
            key_sampled_stage2 <= 1'b1;
            key_stable_stage2 <= 1'b1;
            key_valid_stage2 <= 0;
        end else begin
            current_state_stage2 <= current_state_stage1;
            debounce_counter_stage2 <= debounce_counter_stage1;
            key_sampled_stage2 <= key_sampled_stage1;
            
            if (current_state_stage1 == DEBOUNCE && debounce_counter_stage1 == COUNTER_MAX) begin
                key_stable_stage2 <= key_sampled_stage1;
                key_valid_stage2 <= 1;
            end else begin
                key_valid_stage2 <= 0;
            end
        end
    end

    // Stage 3: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_stable_stage3 <= 1'b1;
            key_valid_stage3 <= 0;
        end else begin
            key_stable_stage3 <= key_stable_stage2;
            key_valid_stage3 <= key_valid_stage2;
        end
    end

    // Next state logic
    always @(*) begin
        next_state_stage1 = current_state_stage1;
        case(current_state_stage1)
            IDLE: if (key_stable_stage3 != key_raw_stage1) next_state_stage1 = DEBOUNCE;
            DEBOUNCE: begin
                if (debounce_counter_stage1 >= COUNTER_MAX) begin
                    next_state_stage1 = IDLE;
                end
                if (key_raw_stage1 != key_sampled_stage1) begin
                    next_state_stage1 = IDLE;
                end
            end
            default: next_state_stage1 = IDLE;
        endcase
    end

    // Output assignments
    assign key_stable = key_stable_stage3;
    assign key_valid = key_valid_stage3;
endmodule