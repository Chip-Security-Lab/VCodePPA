//SystemVerilog
module crypto_rng #(parameter WIDTH = 32, SEED_WIDTH = 16) (
    input wire clock, resetb,
    input wire [SEED_WIDTH-1:0] seed,
    input wire load_seed, get_random,
    output reg [WIDTH-1:0] random_out,
    output reg valid
);
    // Internal state register
    reg [WIDTH-1:0] state;
    
    // Pre-compute combinational logic before registering
    wire [WIDTH-1:0] rotated_state = {state[7:0], state[WIDTH-1:8]};
    wire [WIDTH-1:0] sum = state + rotated_state;
    wire [WIDTH-1:0] shifted_state = {state[WIDTH-2:0], state[WIDTH-1]};
    wire [WIDTH-1:0] xor_result = shifted_state ^ sum;
    wire [WIDTH-1:0] random_value = state ^ xor_result;
    
    // Pipeline control signals (moved forward through combinational logic)
    reg load_seed_pipe1, get_random_pipe1;
    reg valid_pipe1, valid_pipe2;
    
    // Pipeline data registers (rearranged for better timing)
    reg [WIDTH-1:0] xor_result_reg;
    reg [WIDTH-1:0] random_value_reg;
    
    // First stage: Register control signals and pre-compute values
    always @(posedge clock or negedge resetb) begin
        if (!resetb) begin
            load_seed_pipe1 <= 0;
            get_random_pipe1 <= 0;
            valid_pipe1 <= 0;
        end else begin
            load_seed_pipe1 <= load_seed;
            get_random_pipe1 <= get_random;
            valid_pipe1 <= get_random;
        end
    end
    
    // State update logic with optimized timing
    always @(posedge clock or negedge resetb) begin
        if (!resetb) begin
            state <= {WIDTH{1'b1}};
            xor_result_reg <= 0;
        end else begin
            if (load_seed) begin
                state <= {seed, seed};
            end else if (get_random) begin
                // Store the XOR result for the next stage
                xor_result_reg <= xor_result;
                // Update state right away based on pre-computed values
                state <= xor_result;
            end
        end
    end
    
    // Output stage with forward-retimed registers
    always @(posedge clock or negedge resetb) begin
        if (!resetb) begin
            random_value_reg <= 0;
            valid_pipe2 <= 0;
            random_out <= 0;
            valid <= 0;
        end else begin
            // Pipeline the valid signal
            valid_pipe2 <= valid_pipe1;
            valid <= valid_pipe2;
            
            // Pre-register the random value
            random_value_reg <= random_value;
            
            // Final output stage
            if (valid_pipe2) begin
                random_out <= random_value_reg;
            end
        end
    end
endmodule