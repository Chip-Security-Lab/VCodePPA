//SystemVerilog
module debug_icmu #(
    parameter INT_COUNT = 8
)(
    input clk, reset_n,
    input [INT_COUNT-1:0] interrupts,
    input debug_mode,
    input debug_step,
    input debug_int_override,
    input [2:0] debug_force_int,
    output reg [2:0] int_id,
    output reg int_valid,
    output reg [INT_COUNT-1:0] int_history,
    output reg [7:0] int_counts [0:INT_COUNT-1]
);

    // Pipeline stage 1 registers
    reg [INT_COUNT-1:0] int_pending_stage1;
    reg [INT_COUNT-1:0] interrupts_stage1;
    reg debug_mode_stage1;
    reg debug_step_stage1;
    reg debug_int_override_stage1;
    reg [2:0] debug_force_int_stage1;
    reg [INT_COUNT-1:0] int_history_stage1;
    reg [7:0] int_counts_stage1 [0:INT_COUNT-1];
    
    // Pipeline stage 2 registers
    reg [INT_COUNT-1:0] int_pending_stage2;
    reg [2:0] int_id_stage2;
    reg int_valid_stage2;
    reg [INT_COUNT-1:0] int_history_stage2;
    reg [7:0] int_counts_stage2 [0:INT_COUNT-1];
    
    // Intermediate signals for control flow simplification
    reg [2:0] next_int_id;
    reg has_pending_int;
    reg debug_handling_active;
    reg normal_handling_active;
    
    // Han-Carlson adder signals
    wire [7:0] sum [0:INT_COUNT-1];
    wire [7:0] carry [0:INT_COUNT-1];
    wire [7:0] prop [0:INT_COUNT-1];
    wire [7:0] gen [0:INT_COUNT-1];
    
    integer i;
    
    // Han-Carlson adder implementation
    generate
        for (genvar j = 0; j < INT_COUNT; j=j+1) begin : adder_chain
            // First stage: Generate P and G
            assign prop[j][0] = interrupts[j] ^ int_pending_stage1[j];
            assign gen[j][0] = interrupts[j] & int_pending_stage1[j];
            
            // Second stage: Parallel prefix computation
            assign prop[j][1] = prop[j][0] & prop[j][0];
            assign gen[j][1] = gen[j][0] | (prop[j][0] & gen[j][0]);
            
            // Third stage: Parallel prefix computation
            assign prop[j][2] = prop[j][1] & prop[j][1];
            assign gen[j][2] = gen[j][1] | (prop[j][1] & gen[j][1]);
            
            // Fourth stage: Parallel prefix computation
            assign prop[j][3] = prop[j][2] & prop[j][2];
            assign gen[j][3] = gen[j][2] | (prop[j][2] & gen[j][2]);
            
            // Fifth stage: Parallel prefix computation
            assign prop[j][4] = prop[j][3] & prop[j][3];
            assign gen[j][4] = gen[j][3] | (prop[j][3] & gen[j][3]);
            
            // Sixth stage: Parallel prefix computation
            assign prop[j][5] = prop[j][4] & prop[j][4];
            assign gen[j][5] = gen[j][4] | (prop[j][4] & gen[j][4]);
            
            // Seventh stage: Parallel prefix computation
            assign prop[j][6] = prop[j][5] & prop[j][5];
            assign gen[j][6] = gen[j][5] | (prop[j][5] & gen[j][5]);
            
            // Final stage: Sum computation
            assign sum[j] = prop[j][6] ^ gen[j][6];
            assign carry[j] = gen[j][6];
        end
    endgenerate
    
    // Stage 1: Input capture and history update
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            int_pending_stage1 <= {INT_COUNT{1'b0}};
            interrupts_stage1 <= {INT_COUNT{1'b0}};
            debug_mode_stage1 <= 1'b0;
            debug_step_stage1 <= 1'b0;
            debug_int_override_stage1 <= 1'b0;
            debug_force_int_stage1 <= 3'd0;
            int_history_stage1 <= {INT_COUNT{1'b0}};
            for (i = 0; i < INT_COUNT; i=i+1)
                int_counts_stage1[i] <= 8'd0;
        end else begin
            interrupts_stage1 <= interrupts;
            debug_mode_stage1 <= debug_mode;
            debug_step_stage1 <= debug_step;
            debug_int_override_stage1 <= debug_int_override;
            debug_force_int_stage1 <= debug_force_int;
            
            // Capture interrupt history
            int_history_stage1 <= int_history | interrupts;
            
            // Update interrupt counters using Han-Carlson adder
            for (i = 0; i < INT_COUNT; i=i+1) begin
                if (interrupts[i] && !int_pending_stage1[i])
                    int_counts_stage1[i] <= sum[i];
                else
                    int_counts_stage1[i] <= int_counts[i];
            end
            
            // Latch pending interrupts
            int_pending_stage1 <= int_pending_stage1 | interrupts;
        end
    end
    
    // Pre-compute control signals for Stage 2
    always @(*) begin
        // Check if there are any pending interrupts
        has_pending_int = |int_pending_stage1;
        
        // Determine which handling path is active
        debug_handling_active = debug_mode_stage1;
        normal_handling_active = !debug_mode_stage1 && has_pending_int;
        
        // Calculate next interrupt ID
        next_int_id = get_next_int(int_pending_stage1);
    end
    
    // Stage 2: Interrupt processing and output generation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            int_pending_stage2 <= {INT_COUNT{1'b0}};
            int_id_stage2 <= 3'd0;
            int_valid_stage2 <= 1'b0;
            int_history_stage2 <= {INT_COUNT{1'b0}};
            for (i = 0; i < INT_COUNT; i=i+1)
                int_counts_stage2[i] <= 8'd0;
        end else begin
            // Default assignments
            int_pending_stage2 <= int_pending_stage1;
            int_history_stage2 <= int_history_stage1;
            for (i = 0; i < INT_COUNT; i=i+1)
                int_counts_stage2[i] <= int_counts_stage1[i];
            
            // Initialize outputs
            int_valid_stage2 <= 1'b0;
            
            // Debug mode handling
            if (debug_handling_active) begin
                if (debug_int_override_stage1) begin
                    int_id_stage2 <= debug_force_int_stage1;
                    int_valid_stage2 <= 1'b1;
                end else if (debug_step_stage1 && has_pending_int) begin
                    int_id_stage2 <= next_int_id;
                    int_valid_stage2 <= 1'b1;
                    int_pending_stage2[next_int_id] <= 1'b0;
                end
            end 
            // Normal operation
            else if (normal_handling_active) begin
                int_id_stage2 <= next_int_id;
                int_valid_stage2 <= 1'b1;
                int_pending_stage2[next_int_id] <= 1'b0;
            end
        end
    end
    
    // Output stage
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            int_id <= 3'd0;
            int_valid <= 1'b0;
            int_history <= {INT_COUNT{1'b0}};
            for (i = 0; i < INT_COUNT; i=i+1)
                int_counts[i] <= 8'd0;
        end else begin
            int_id <= int_id_stage2;
            int_valid <= int_valid_stage2;
            int_history <= int_history_stage2;
            for (i = 0; i < INT_COUNT; i=i+1)
                int_counts[i] <= int_counts_stage2[i];
        end
    end
    
    function [2:0] get_next_int;
        input [INT_COUNT-1:0] pending;
        reg [2:0] result;
        integer j;
        begin
            result = 3'd0;
            for (j = INT_COUNT-1; j >= 0; j=j-1)
                if (pending[j]) result = j[2:0];
            get_next_int = result;
        end
    endfunction
endmodule