//SystemVerilog
module skip_state_ring_counter(
    input wire clock,
    input wire reset,
    input wire skip,      // Skip next state
    input wire data_valid, // Input data valid signal
    output reg [3:0] state,
    output reg data_ready  // Output ready signal
);
    // Modified pipeline registers with pre-computed transitions
    reg [3:0] state_stage1;
    reg [3:0] normal_transition;    // Pre-computed normal transition
    reg [3:0] skip_transition;      // Pre-computed skip transition
    reg skip_stage1;
    reg valid_stage1;
    reg valid_stage2;
    
    // Pre-compute both possible next states in parallel
    always @(*) begin
        normal_transition = {state_stage1[2:0], state_stage1[3]};    // Normal rotation
        skip_transition = {state_stage1[1:0], state_stage1[3:2]};    // Skip rotation
    end
    
    // Stage 1: Input capture with reset synchronization
    always @(posedge clock) begin
        if (reset) begin
            state_stage1 <= 4'b0001;
            skip_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            if (data_valid) begin
                state_stage1 <= state;
                skip_stage1 <= skip;
                valid_stage1 <= 1'b1;
            end
            else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Final stage: Output registration with transition selection
    // Combined stages 2 and 3 to reduce pipeline latency
    always @(posedge clock) begin
        if (reset) begin
            state <= 4'b0001;
            data_ready <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
            
            if (valid_stage1) begin
                // Select between normal and skip transition paths (balanced)
                state <= skip_stage1 ? skip_transition : normal_transition;
            end
            
            // Data ready follows valid with one cycle delay
            data_ready <= valid_stage2;
        end
    end
endmodule