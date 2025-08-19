//SystemVerilog
// SystemVerilog
// Top module for 8-bit subtractor using hierarchical design with pipelined dataflow

// Submodule for calculating two's complement (Stage 1)
module twos_complement_stage1 (
    input wire [7:0] data_in_s1,
    output wire [7:0] data_out_s1
);

    // Calculate two's complement: invert all bits and add 1
    assign data_out_s1 = ~data_in_s1 + 8'd1;

endmodule

// Submodule for 9-bit adder (Stage 2)
module adder_stage2 (
    input wire [8:0] data_a_s2,
    input wire [8:0] data_b_s2,
    output wire [8:0] data_sum_s2
);

    // Perform 9-bit addition
    assign data_sum_s2 = data_a_s2 + data_b_s2;

endmodule

// Top level module for 8-bit subtractor with a two-stage pipeline
module subtractor_8bit_pipelined (
    input wire clk,
    input wire reset,
    input wire [7:0] A_in,
    input wire [7:0] B_in,
    output wire [7:0] Y_out
);

    // Stage 1 signals
    wire [7:0] b_twos_complement_s1;

    // Stage 1 registers
    reg [7:0] a_reg_s2;
    reg [7:0] b_twos_complement_reg_s2;

    // Stage 2 signals
    wire [8:0] sum_s2;

    // Stage 2 registers
    reg [7:0] y_reg_out;

    // Stage 1: Calculate two's complement of B
    twos_complement_stage1 u_twos_complement_s1 (
        .data_in_s1  (B_in),
        .data_out_s1 (b_twos_complement_s1)
    );

    // Pipeline registers between Stage 1 and Stage 2
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_reg_s2 <= 8'b0;
            b_twos_complement_reg_s2 <= 8'b0;
        end else begin
            a_reg_s2 <= A_in; // Register A for Stage 2
            b_twos_complement_reg_s2 <= b_twos_complement_s1; // Register B's two's complement for Stage 2
        end
    end

    // Stage 2: Perform 9-bit addition
    adder_stage2 u_adder_s2 (
        .data_a_s2 ( {1'b0, a_reg_s2} ), // Zero-extend registered A to 9 bits
        .data_b_s2 ( {1'b0, b_twos_complement_reg_s2} ), // Zero-extend registered B's two's complement to 9 bits
        .data_sum_s2 (sum_s2)
    );

    // Pipeline register for the final output
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            y_reg_out <= 8'b0;
        end else begin
            // The result of the subtraction is the lower 8 bits of the sum
            y_reg_out <= sum_s2[7:0];
        end
    end

    // Final output assignment
    assign Y_out = y_reg_out;

endmodule