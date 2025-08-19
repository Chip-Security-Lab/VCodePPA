//SystemVerilog
module skip_state_ring_counter(
    input wire clock,
    input wire reset,
    input wire skip,        // Skip next state
    input wire valid_in,    // Input valid signal
    output wire valid_out,  // Output valid signal
    output wire [3:0] state // Current state
);
    // Pipeline stage registers
    reg [3:0] state_stage1;
    reg valid_stage1;
    reg skip_stage1;
    
    reg [3:0] state_stage2;
    reg valid_stage2;
    
    // Next state calculation logic
    wire [3:0] next_state_normal = {state_stage2[2:0], state_stage2[3]};   // Normal shift
    wire [3:0] next_state_skip = {state_stage2[1:0], state_stage2[3:2]};   // Skip shift
    wire [3:0] next_state = skip ? next_state_skip : next_state_normal;
    
    // Stage 1: Input and state calculation
    always @(posedge clock) begin
        if (reset) begin
            state_stage1 <= 4'b0001;
            valid_stage1 <= 1'b0;
            skip_stage1 <= 1'b0;
        end
        else begin
            valid_stage1 <= valid_in;
            skip_stage1 <= skip;
            
            if (valid_in) begin
                state_stage1 <= next_state;
            end
        end
    end
    
    // Stage 2: Output stage with single enable condition
    always @(posedge clock) begin
        if (reset) begin
            state_stage2 <= 4'b0001;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            state_stage2 <= state_stage1;
            valid_stage2 <= valid_stage1;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Output assignments
    assign state = state_stage2;
    assign valid_out = valid_stage2;
    
endmodule