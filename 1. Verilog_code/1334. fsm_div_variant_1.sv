//SystemVerilog
// Top-level module
module fsm_div #(parameter EVEN=4, ODD=5) (
    input  wire clk,
    input  wire mode,
    input  wire rst_n,
    output wire clk_out
);
    // Internal connections
    wire [2:0] state;
    wire       state_reset;
    wire [2:0] next_state;
    
    // Combinational logic module instantiation
    fsm_comb_logic #(
        .EVEN(EVEN),
        .ODD(ODD)
    ) fsm_comb_logic_inst (
        .mode       (mode),
        .state      (state),
        .next_state (next_state),
        .state_reset(state_reset),
        .clk_out    (clk_out)
    );
    
    // Sequential logic module instantiation
    fsm_seq_logic fsm_seq_logic_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .next_state (next_state),
        .state      (state)
    );
    
endmodule

// Module for all combinational logic
module fsm_comb_logic #(parameter EVEN=4, ODD=5) (
    input  wire       mode,
    input  wire [2:0] state,
    output wire [2:0] next_state,
    output wire       state_reset,
    output wire       clk_out
);
    // Division parameters
    wire [2:0] dividend;
    wire [2:0] divisor;
    wire [2:0] half_threshold;
    wire [2:0] max_threshold;
    
    // Determine division operands based on mode
    assign divisor = 3'b010;  // Always divide by 2
    assign max_threshold = mode ? ODD-1 : EVEN-1;
    
    // Non-restoring divider for half value calculation
    non_restoring_divider divider_inst (
        .dividend(max_threshold + 3'b001),
        .divisor(divisor),
        .quotient(half_threshold)
    );
    
    // State reset logic
    assign state_reset = (state == max_threshold);
    
    // Next state computation
    assign next_state = state_reset ? 3'b000 : state + 3'b001;
    
    // Output generation using comparison with calculated half value
    assign clk_out = (state >= half_threshold);
    
endmodule

// Non-restoring division algorithm implementation (3-bit)
module non_restoring_divider (
    input  wire [2:0] dividend,
    input  wire [2:0] divisor,
    output wire [2:0] quotient
);
    wire [3:0] partial_remainder[0:3];  // Partial remainders with extra bit
    wire [2:0] quotient_bits;           // Individual quotient bits
    
    // Initial partial remainder (0 || dividend[2])
    assign partial_remainder[0] = {1'b0, dividend[2], 2'b00};
    
    // Step 1: First bit calculation
    assign quotient_bits[2] = ~partial_remainder[0][3];
    assign partial_remainder[1] = quotient_bits[2] ? 
                               {partial_remainder[0][2:0], dividend[1]} - {1'b0, divisor} :
                               {partial_remainder[0][2:0], dividend[1]} + {1'b0, divisor};
    
    // Step 2: Second bit calculation
    assign quotient_bits[1] = ~partial_remainder[1][3];
    assign partial_remainder[2] = quotient_bits[1] ? 
                               {partial_remainder[1][2:0], dividend[0]} - {1'b0, divisor} :
                               {partial_remainder[1][2:0], dividend[0]} + {1'b0, divisor};
    
    // Step 3: Third bit calculation
    assign quotient_bits[0] = ~partial_remainder[2][3];
    assign partial_remainder[3] = quotient_bits[0] ? 
                               {partial_remainder[2][2:0], 1'b0} - {1'b0, divisor} :
                               {partial_remainder[2][2:0], 1'b0} + {1'b0, divisor};
    
    // Final correction step if needed
    wire [2:0] raw_quotient;
    assign raw_quotient = quotient_bits;
    
    // Correction when remainder is negative
    wire final_correction_needed;
    assign final_correction_needed = partial_remainder[3][3];
    
    // Final quotient
    assign quotient = final_correction_needed ? raw_quotient - 3'b001 : raw_quotient;
    
endmodule

// Module for all sequential logic
module fsm_seq_logic (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] next_state,
    output reg  [2:0] state
);
    // State register with synchronous reset
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= 3'b000;
        end else begin
            state <= next_state;
        end
    end
    
endmodule