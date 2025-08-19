//SystemVerilog
module quad_clock_gen(
    input clock_in,
    input reset,
    output reg clock_0,
    output reg clock_90,
    output reg clock_180,
    output reg clock_270
);
    // Two-bit counter to track the phase
    reg [1:0] phase_counter;
    
    // One-hot encoded phase signals for direct assignment
    reg [3:0] phase_onehot; // [phase_270, phase_180, phase_90, phase_0]
    
    // Intermediate registers for pipelining
    reg [3:0] phase_onehot_pipe;
    
    // Stage 1: Phase counter with optimized reset path
    always @(posedge clock_in) begin
        if (reset)
            phase_counter <= 2'b00;
        else
            phase_counter <= phase_counter + 1'b1;
    end
    
    // Stage 2: One-hot phase encoding using direct binary decoding
    always @(posedge clock_in) begin
        if (reset)
            phase_onehot <= 4'b0001; // Initialize with phase 0 active
        else begin
            // Binary to one-hot conversion using a case statement
            // This optimizes the compare chain implementation
            case(phase_counter)
                2'b00: phase_onehot <= 4'b0001;
                2'b01: phase_onehot <= 4'b0010;
                2'b10: phase_onehot <= 4'b0100;
                2'b11: phase_onehot <= 4'b1000;
            endcase
        end
    end
    
    // Stage 3: Final output generation with pipelining
    always @(posedge clock_in) begin
        if (reset) begin
            phase_onehot_pipe <= 4'b0001;
            {clock_270, clock_180, clock_90, clock_0} <= 4'b0000;
        end else begin
            phase_onehot_pipe <= phase_onehot;
            {clock_270, clock_180, clock_90, clock_0} <= phase_onehot_pipe;
        end
    end
endmodule