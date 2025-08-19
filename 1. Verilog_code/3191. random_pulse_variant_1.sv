//SystemVerilog
// LFSR submodule for random number generation
module lfsr_core #(
    parameter LFSR_WIDTH = 8,
    parameter SEED = 8'h2B
)(
    input clk,
    input rst,
    output reg [LFSR_WIDTH-1:0] lfsr_out
);
    reg [LFSR_WIDTH-1:0] lfsr;
    reg feedback_bit;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr <= SEED;
            feedback_bit <= 1'b0;
        end else begin
            // Calculate feedback bit
            feedback_bit <= lfsr[7] ^ lfsr[3] ^ lfsr[2] ^ lfsr[0];
            
            // Update LFSR
            lfsr <= {lfsr[LFSR_WIDTH-2:0], feedback_bit};
        end
    end
    
    always @(*) begin
        lfsr_out = lfsr;
    end
endmodule

// Optimized comparator using parallel prefix subtractor
module threshold_comparator #(
    parameter LFSR_WIDTH = 8,
    parameter THRESHOLD = 8'h20
)(
    input [LFSR_WIDTH-1:0] lfsr_value,
    output reg compare_result
);
    // Internal signals for parallel prefix subtractor
    wire [LFSR_WIDTH-1:0] b_complement;
    wire [LFSR_WIDTH-1:0] subtract_result;
    wire [LFSR_WIDTH:0] gen_p [LFSR_WIDTH-1:0];  // Generate and propagate signals
    wire [LFSR_WIDTH:0] carry;                   // Carry signals
    wire borrow_out;                             // Final borrow
    
    // 1's complement of subtrahend (THRESHOLD)
    assign b_complement = ~THRESHOLD;
    
    // Stage 1: Generate initial propagate and generate signals
    genvar i;
    generate
        for (i = 0; i < LFSR_WIDTH; i = i + 1) begin: stage1
            // Generate (g) and propagate (p) for each bit position
            assign gen_p[i][0] = lfsr_value[i] & b_complement[i];
            assign gen_p[i][1] = lfsr_value[i] | b_complement[i];
        end
    endgenerate
    
    // Stage 2: Compute parallel prefix for carries
    // Initial carry-in (for subtraction, this is 1)
    assign carry[0] = 1'b1;
    
    // Calculate carries using parallel prefix structure (Kogge-Stone implementation)
    generate
        // Level 1 prefix computation
        for (i = 0; i < LFSR_WIDTH; i = i + 1) begin: level1
            if (i == 0) begin
                assign carry[i+1] = gen_p[i][0] | (gen_p[i][1] & carry[i]);
            end else begin
                assign carry[i+1] = gen_p[i][0] | (gen_p[i][1] & carry[i]);
            end
        end
    endgenerate
    
    // Stage 3: Calculate final result
    generate
        for (i = 0; i < LFSR_WIDTH; i = i + 1) begin: sum_stage
            assign subtract_result[i] = lfsr_value[i] ^ b_complement[i] ^ carry[i];
        end
    endgenerate
    
    // Final borrow out (inverted MSB carry indicates borrow)
    assign borrow_out = ~carry[LFSR_WIDTH-1];
    
    // Comparison result: if borrow_out is 1, lfsr_value < THRESHOLD
    always @(*) begin
        compare_result = borrow_out;
    end
endmodule

// Top-level module
module random_pulse #(
    parameter LFSR_WIDTH = 8,
    parameter SEED = 8'h2B,
    parameter THRESHOLD = 8'h20
)(
    input clk,
    input rst,
    output reg pulse
);
    wire [LFSR_WIDTH-1:0] lfsr_value;
    wire compare_result;
    
    // Instantiate LFSR core
    lfsr_core #(
        .LFSR_WIDTH(LFSR_WIDTH),
        .SEED(SEED)
    ) lfsr_inst (
        .clk(clk),
        .rst(rst),
        .lfsr_out(lfsr_value)
    );
    
    // Instantiate threshold comparator
    threshold_comparator #(
        .LFSR_WIDTH(LFSR_WIDTH),
        .THRESHOLD(THRESHOLD)
    ) comp_inst (
        .lfsr_value(lfsr_value),
        .compare_result(compare_result)
    );
    
    // Output pulse register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pulse <= 1'b0;
        end else begin
            pulse <= compare_result;
        end
    end
endmodule