//SystemVerilog
module random_number_generator(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [7:0] seed,
    input wire load_seed,
    output reg [15:0] random_value,
    output reg valid,      // New valid signal
    input wire ready       // New ready signal
);
    // FSM states
    localparam [1:0] IDLE = 2'b00, 
                     LOAD = 2'b01, 
                     GENERATE = 2'b10;
                     
    // State registers
    reg [1:0] state, next_state;
    
    // LFSR registers and signals
    reg [15:0] lfsr_reg;
    reg feedback_bit;
    
    // Control signals for improved readability
    reg update_lfsr;
    reg load_new_seed;
    reg generate_random;
    
    // Sequential logic for state and data registers
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            lfsr_reg <= 16'h1234; // Default seed
            random_value <= 16'h0000;
            valid <= 1'b0;        // Reset valid signal
        end else begin
            // State update
            state <= next_state;
            
            // LFSR and random value updates
            if (load_new_seed) begin
                lfsr_reg <= {seed, 8'h01}; // Ensure not all zeros
            end else if (generate_random) begin
                feedback_bit = lfsr_reg[15] ^ lfsr_reg[14] ^ lfsr_reg[12] ^ lfsr_reg[3];
                lfsr_reg <= {lfsr_reg[14:0], feedback_bit};
                random_value <= lfsr_reg;
                valid <= 1'b1;        // Set valid when data is ready
            end else if (ready) begin
                valid <= 1'b0;        // Clear valid when ready is high
            end
        end
    end
    
    // Combinational logic for control signals
    always @(*) begin
        // Default values to prevent latches
        load_new_seed = 1'b0;
        generate_random = 1'b0;
        
        case (state)
            IDLE: begin
                // No operations in IDLE state
            end
            LOAD: begin
                load_new_seed = 1'b1;
            end
            GENERATE: begin
                generate_random = enable;
            end
            default: begin
                // Safe defaults
            end
        endcase
    end
    
    // Next state logic with simplified conditions
    always @(*) begin
        // Default next state to prevent latches
        next_state = state;
        
        case (state)
            IDLE: begin
                if (load_seed) begin
                    next_state = LOAD;
                end else if (enable) begin
                    next_state = GENERATE;
                end
            end
            LOAD: begin
                next_state = GENERATE;
            end
            GENERATE: begin
                if (load_seed) begin
                    next_state = LOAD;
                end else if (!enable) begin
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule