//SystemVerilog
module lfsr_waveform(
    input i_clk,
    input i_rst,
    input i_enable,
    output [7:0] o_random
);

    // Pipeline stage registers
    reg [15:0] lfsr_state;
    reg [15:0] lfsr_next;
    reg [7:0] random_output;
    
    // Tap selection stage
    wire [3:0] tap_bits = {
        lfsr_state[15],  // tap_bit15
        lfsr_state[14],  // tap_bit14
        lfsr_state[12],  // tap_bit12
        lfsr_state[3]    // tap_bit3
    };
    
    // Feedback calculation pipeline
    reg feedback_stage1;
    reg feedback_stage2;
    reg feedback_final;
    
    // Stage 1: First XOR operation
    always @(*) begin
        feedback_stage1 = tap_bits[3] ^ tap_bits[2];
    end
    
    // Stage 2: Second XOR operation
    always @(*) begin
        feedback_stage2 = feedback_stage1 ^ tap_bits[1];
    end
    
    // Stage 3: Final XOR operation
    always @(*) begin
        feedback_final = feedback_stage2 ^ tap_bits[0];
    end
    
    // LFSR state update pipeline
    always @(*) begin
        lfsr_next = {lfsr_state[14:0], feedback_final};
    end
    
    // Main sequential logic
    always @(posedge i_clk) begin
        if (i_rst) begin
            lfsr_state <= 16'hACE1;
            random_output <= 8'h00;
        end else if (i_enable) begin
            lfsr_state <= lfsr_next;
            random_output <= lfsr_next[7:0];
        end
    end
    
    // Output assignment
    assign o_random = random_output;
    
endmodule