//SystemVerilog
module crypto_rng #(parameter WIDTH = 32, SEED_WIDTH = 16) (
    input wire clock, resetb,
    input wire [SEED_WIDTH-1:0] seed,
    input wire load_seed, get_random,
    output reg [WIDTH-1:0] random_out,
    output reg valid
);
    // Pipeline stage registers
    reg [WIDTH-1:0] state_stage1;
    reg [WIDTH-1:0] state_stage2;
    reg [WIDTH-1:0] next_state_stage1;
    reg [WIDTH-1:0] shifted_state_stage1;
    reg [WIDTH-1:0] sum_stage1;
    
    // Control signals for pipeline
    reg [1:0] control_stage1;
    reg [1:0] control_stage2;
    reg load_seed_stage1, get_random_stage1;
    
    // Pipeline valid signals
    reg valid_stage1;
    
    // Stage 1: Input registration and initial computation
    always @(posedge clock or negedge resetb) begin
        if (!resetb) begin
            state_stage1 <= {WIDTH{1'b1}};
            control_stage1 <= 2'b00;
            load_seed_stage1 <= 1'b0;
            get_random_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            // Register control signals
            load_seed_stage1 <= load_seed;
            get_random_stage1 <= get_random;
            
            // Determine control state
            if (!resetb)
                control_stage1 <= 2'b00;
            else if (load_seed)
                control_stage1 <= 2'b01;
            else if (get_random)
                control_stage1 <= 2'b10;
            else
                control_stage1 <= 2'b11;
            
            // First pipeline stage calculations
            shifted_state_stage1 <= {state_stage2[7:0], state_stage2[WIDTH-1:8]};
            
            // Update state based on control signals
            case (control_stage1)
                2'b00: state_stage1 <= {WIDTH{1'b1}}; // Reset
                2'b01: state_stage1 <= {seed, seed};  // Load seed
                2'b10: state_stage1 <= state_stage2;  // Use current state
                2'b11: state_stage1 <= state_stage2;  // Maintain state
            endcase
            
            valid_stage1 <= (control_stage1 == 2'b10);
        end
    end
    
    // Stage 2: Complete computation and output
    always @(posedge clock or negedge resetb) begin
        if (!resetb) begin
            state_stage2 <= {WIDTH{1'b1}};
            sum_stage1 <= {WIDTH{1'b0}};
            next_state_stage1 <= {WIDTH{1'b0}};
            control_stage2 <= 2'b00;
            valid <= 1'b0;
            random_out <= {WIDTH{1'b0}};
        end else begin
            // Register control for stage 2
            control_stage2 <= control_stage1;
            
            // Pipeline stage 2 computations
            sum_stage1 <= state_stage1 + shifted_state_stage1;
            next_state_stage1 <= {state_stage1[WIDTH-2:0], state_stage1[WIDTH-1]} ^ 
                             (state_stage1 + shifted_state_stage1);
            
            // Final state update and output generation
            if (control_stage1 == 2'b10) begin
                state_stage2 <= next_state_stage1;
                random_out <= state_stage1 ^ next_state_stage1;
                valid <= valid_stage1;
            end else begin
                state_stage2 <= state_stage1;
                valid <= 1'b0;
            end
        end
    end
endmodule