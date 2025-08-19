//SystemVerilog
module crypto_rng #(parameter WIDTH = 32, SEED_WIDTH = 16) (
    input wire clock, resetb,
    input wire [SEED_WIDTH-1:0] seed,
    input wire load_seed, get_random,
    output reg [WIDTH-1:0] random_out,
    output reg valid
);
    // Pipeline stage registers
    reg [WIDTH-1:0] state;
    reg [WIDTH-1:0] rotated_state_stage1;
    reg [WIDTH-1:0] added_state_stage1;
    reg [WIDTH-1:0] xored_state_stage2;
    reg get_random_stage1, get_random_stage2;
    reg load_seed_stage1;
    reg [WIDTH-1:0] state_stage1, state_stage2;
    
    // Stage 1: Compute components for next state
    wire [WIDTH-1:0] rotated_state = {state[WIDTH-2:0], state[WIDTH-1]};
    wire [WIDTH-1:0] shifted_state = {state[7:0], state[WIDTH-1:8]};
    
    // Pipeline control signals
    always @(posedge clock or negedge resetb) begin
        if (!resetb) begin
            get_random_stage1 <= 0;
            get_random_stage2 <= 0;
            load_seed_stage1 <= 0;
        end else begin
            get_random_stage1 <= get_random;
            get_random_stage2 <= get_random_stage1;
            load_seed_stage1 <= load_seed;
        end
    end
    
    // Pipeline stage 1: Register intermediate computations
    always @(posedge clock or negedge resetb) begin
        if (!resetb) begin
            rotated_state_stage1 <= {WIDTH{1'b1}};
            added_state_stage1 <= {WIDTH{1'b1}};
            state_stage1 <= {WIDTH{1'b1}};
        end else begin
            rotated_state_stage1 <= rotated_state;
            added_state_stage1 <= state + shifted_state;
            state_stage1 <= state;
        end
    end
    
    // Pipeline stage 2: Complete the state computation
    always @(posedge clock or negedge resetb) begin
        if (!resetb) begin
            xored_state_stage2 <= {WIDTH{1'b1}};
            state_stage2 <= {WIDTH{1'b1}};
        end else begin
            xored_state_stage2 <= rotated_state_stage1 ^ added_state_stage1;
            state_stage2 <= state_stage1;
        end
    end
    
    // Final state update and output generation
    always @(posedge clock or negedge resetb) begin
        if (!resetb) begin
            state <= {WIDTH{1'b1}};
            random_out <= {WIDTH{1'b0}};
            valid <= 0;
        end else begin
            // State update logic
            if (load_seed) begin
                state <= {seed, seed};
                valid <= 0;
            end else if (load_seed_stage1) begin
                // Wait one cycle after seed load
                valid <= 0;
            end else if (get_random_stage2) begin
                // Update state with the fully computed next state
                state <= xored_state_stage2;
                random_out <= state_stage2 ^ xored_state_stage2;
                valid <= 1;
            end else begin
                valid <= 0;
            end
        end
    end
endmodule