//SystemVerilog
// SystemVerilog
module nor4_reset (
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire [7:0] C,
    input  wire [7:0] D,
    input  wire       reset,
    output reg  [15:0] Y
);

    // Stage 1: OR/NOR computation and pipeline register
    wire [7:0] or_stage1_result;
    wire [7:0] nor_stage1_result;
    reg  [7:0] nor_stage2_reg;

    assign or_stage1_result  = A | B | C | D;
    assign nor_stage1_result = ~or_stage1_result;

    always @(posedge reset or posedge nor_stage1_result[0]) begin
        if (reset)
            nor_stage2_reg <= 8'd0;
        else
            nor_stage2_reg <= nor_stage1_result;
    end

    // Stage 2: Karatsuba multiplication (pipelined)
    wire [15:0] karatsuba_stage2_out;
    reg  [15:0] karatsuba_stage3_reg;

    karatsuba_mult8_pipeline karatsuba_pipe_inst (
        .clk(reset),
        .operand_a(nor_stage2_reg),
        .operand_b(nor_stage2_reg),
        .product(karatsuba_stage2_out)
    );

    always @(posedge reset or posedge karatsuba_stage2_out[0]) begin
        if (reset)
            karatsuba_stage3_reg <= 16'd0;
        else
            karatsuba_stage3_reg <= karatsuba_stage2_out;
    end

    // Stage 3: Output stage with pipeline and reset
    always @(*) begin
        if (reset)
            Y = 16'hFFFF;
        else
            Y = karatsuba_stage3_reg;
    end

endmodule

// Pipelined 8-bit Karatsuba multiplier
module karatsuba_mult8_pipeline (
    input  wire        clk,
    input  wire [7:0]  operand_a,
    input  wire [7:0]  operand_b,
    output wire [15:0] product
);

    // Stage 1: Split operands and pipeline register
    wire [3:0] a_high_s1, a_low_s1, b_high_s1, b_low_s1;
    reg  [3:0] a_high_s2, a_low_s2, b_high_s2, b_low_s2;

    assign a_high_s1 = operand_a[7:4];
    assign a_low_s1  = operand_a[3:0];
    assign b_high_s1 = operand_b[7:4];
    assign b_low_s1  = operand_b[3:0];

    always @(posedge clk) begin
        a_high_s2 <= a_high_s1;
        a_low_s2  <= a_low_s1;
        b_high_s2 <= b_high_s1;
        b_low_s2  <= b_low_s1;
    end

    // Stage 2: Compute z0, z2, sum_a, sum_b and pipeline
    wire [7:0] z0_s2, z2_s2;
    wire [4:0] sum_a_s2, sum_b_s2;
    reg  [7:0] z0_s3, z2_s3;
    reg  [4:0] sum_a_s3, sum_b_s3;

    karatsuba_mult4_pipeline mult4_z0 (
        .clk(clk),
        .operand_a(a_low_s2),
        .operand_b(b_low_s2),
        .product(z0_s2)
    );

    karatsuba_mult4_pipeline mult4_z2 (
        .clk(clk),
        .operand_a(a_high_s2),
        .operand_b(b_high_s2),
        .product(z2_s2)
    );

    assign sum_a_s2 = a_low_s2 + a_high_s2;
    assign sum_b_s2 = b_low_s2 + b_high_s2;

    always @(posedge clk) begin
        z0_s3    <= z0_s2;
        z2_s3    <= z2_s2;
        sum_a_s3 <= sum_a_s2;
        sum_b_s3 <= sum_b_s2;
    end

    // Stage 3: Compute z1 and pipeline
    wire [15:0] z1_temp_s3;
    wire [7:0]  z1_s3;
    reg  [7:0]  z0_s4, z2_s4, z1_s4;

    karatsuba_mult5 mult5_z1 (
        .operand_a(sum_a_s3),
        .operand_b(sum_b_s3),
        .product(z1_temp_s3)
    );

    assign z1_s3 = z1_temp_s3[7:0] - z2_s3 - z0_s3;

    always @(posedge clk) begin
        z0_s4 <= z0_s3;
        z2_s4 <= z2_s3;
        z1_s4 <= z1_s3;
    end

    // Stage 4: Final product computation
    assign product = {z2_s4, 8'b0} + {z1_s4, 4'b0} + z0_s4;

endmodule

// Pipelined 4-bit Karatsuba multiplier
module karatsuba_mult4_pipeline (
    input  wire        clk,
    input  wire [3:0]  operand_a,
    input  wire [3:0]  operand_b,
    output wire [7:0]  product
);

    // Stage 1: Split operands and pipeline register
    wire [1:0] a_high_s1, a_low_s1, b_high_s1, b_low_s1;
    reg  [1:0] a_high_s2, a_low_s2, b_high_s2, b_low_s2;

    assign a_high_s1 = operand_a[3:2];
    assign a_low_s1  = operand_a[1:0];
    assign b_high_s1 = operand_b[3:2];
    assign b_low_s1  = operand_b[1:0];

    always @(posedge clk) begin
        a_high_s2 <= a_high_s1;
        a_low_s2  <= a_low_s1;
        b_high_s2 <= b_high_s1;
        b_low_s2  <= b_low_s1;
    end

    // Stage 2: Compute z0, z2, sum_a, sum_b and pipeline
    wire [3:0] z0_s2, z2_s2;
    wire [2:0] sum_a_s2, sum_b_s2;
    reg  [3:0] z0_s3, z2_s3;
    reg  [2:0] sum_a_s3, sum_b_s3;

    karatsuba_mult2 mult2_z0 (
        .operand_a(a_low_s2),
        .operand_b(b_low_s2),
        .product(z0_s2)
    );

    karatsuba_mult2 mult2_z2 (
        .operand_a(a_high_s2),
        .operand_b(b_high_s2),
        .product(z2_s2)
    );

    assign sum_a_s2 = a_low_s2 + a_high_s2;
    assign sum_b_s2 = b_low_s2 + b_high_s2;

    always @(posedge clk) begin
        z0_s3    <= z0_s2;
        z2_s3    <= z2_s2;
        sum_a_s3 <= sum_a_s2;
        sum_b_s3 <= sum_b_s2;
    end

    // Stage 3: Compute z1 and pipeline
    wire [7:0] z1_temp_s3;
    wire [3:0] z1_s3;
    reg  [3:0] z0_s4, z2_s4, z1_s4;

    karatsuba_mult3 mult3_z1 (
        .operand_a(sum_a_s3),
        .operand_b(sum_b_s3),
        .product(z1_temp_s3)
    );

    assign z1_s3 = z1_temp_s3[3:0] - z2_s3 - z0_s3;

    always @(posedge clk) begin
        z0_s4 <= z0_s3;
        z2_s4 <= z2_s3;
        z1_s4 <= z1_s3;
    end

    // Stage 4: Final product computation
    assign product = {z2_s4, 4'b0} + {z1_s4, 2'b0} + z0_s4;

endmodule

module karatsuba_mult2 (
    input  wire [1:0] operand_a,
    input  wire [1:0] operand_b,
    output wire [3:0] product
);
    assign product = operand_a * operand_b;
endmodule

module karatsuba_mult3 (
    input  wire [2:0] operand_a,
    input  wire [2:0] operand_b,
    output wire [7:0] product
);
    assign product = operand_a * operand_b;
endmodule

module karatsuba_mult5 (
    input  wire [4:0] operand_a,
    input  wire [4:0] operand_b,
    output wire [15:0] product
);
    assign product = operand_a * operand_b;
endmodule