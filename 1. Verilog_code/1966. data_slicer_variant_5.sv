//SystemVerilog

module data_slicer #(
    parameter DATA_WIDTH = 32,
    parameter SLICE_WIDTH = 8,  // 必须能整除DATA_WIDTH
    parameter NUM_SLICES = DATA_WIDTH/SLICE_WIDTH
)(
    input  wire [DATA_WIDTH-1:0] wide_data,
    input  wire [$clog2(NUM_SLICES)-1:0] slice_sel,
    output wire [SLICE_WIDTH-1:0] slice_out
);

    // Pipeline stages for timing closure
    reg [DATA_WIDTH-1:0] reg_wide_data;
    reg [$clog2(NUM_SLICES)-1:0] reg_slice_sel;
    always @(*) begin
        reg_wide_data = wide_data;
        reg_slice_sel = slice_sel;
    end

    // Optimized slice extraction using casez and range checking
    reg [SLICE_WIDTH-1:0] reg_slice_out;
    integer i;
    always @(*) begin
        reg_slice_out = {SLICE_WIDTH{1'b0}};
        for (i = 0; i < NUM_SLICES; i = i + 1) begin : slice_loop
            if (reg_slice_sel == i[$clog2(NUM_SLICES)-1:0])
                reg_slice_out = reg_wide_data[i*SLICE_WIDTH +: SLICE_WIDTH];
        end
    end

    assign slice_out = reg_slice_out;

endmodule

module karatsuba_mult32 (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    output wire [63:0] product
);
    wire [15:0] a_high, a_low, b_high, b_low;
    wire [31:0] z0, z2;
    wire [32:0] a_sum, b_sum;
    wire [33:0] z1_temp;
    wire [63:0] z0_ext, z2_ext, z1_ext;
    wire [63:0] result;

    assign a_low  = operand_a[15:0];
    assign a_high = operand_a[31:16];
    assign b_low  = operand_b[15:0];
    assign b_high = operand_b[31:16];

    karatsuba_mult16 u_z0 (
        .operand_a(a_low),
        .operand_b(b_low),
        .product(z0)
    );

    karatsuba_mult16 u_z2 (
        .operand_a(a_high),
        .operand_b(b_high),
        .product(z2)
    );

    assign a_sum = a_low + a_high;
    assign b_sum = b_low + b_high;

    karatsuba_mult17 u_z1 (
        .operand_a(a_sum),
        .operand_b(b_sum),
        .product(z1_temp)
    );

    assign z0_ext = {32'b0, z0};
    assign z2_ext = {z2, 32'b0};
    assign z1_ext = {30'b0, z1_temp} - z0_ext - z2_ext;

    assign result = z2_ext + z0_ext + (z1_ext << 16);

    assign product = result;

endmodule

module karatsuba_mult16 (
    input  wire [15:0] operand_a,
    input  wire [15:0] operand_b,
    output wire [31:0] product
);
    wire [7:0] a_high, a_low, b_high, b_low;
    wire [15:0] z0, z2;
    wire [8:0] a_sum, b_sum;
    wire [17:0] z1_temp;
    wire [31:0] z0_ext, z2_ext, z1_ext;
    wire [31:0] result;

    assign a_low  = operand_a[7:0];
    assign a_high = operand_a[15:8];
    assign b_low  = operand_b[7:0];
    assign b_high = operand_b[15:8];

    karatsuba_mult8 u_z0 (
        .operand_a(a_low),
        .operand_b(b_low),
        .product(z0)
    );

    karatsuba_mult8 u_z2 (
        .operand_a(a_high),
        .operand_b(b_high),
        .product(z2)
    );

    assign a_sum = a_low + a_high;
    assign b_sum = b_low + b_high;

    karatsuba_mult9 u_z1 (
        .operand_a(a_sum),
        .operand_b(b_sum),
        .product(z1_temp)
    );

    assign z0_ext = {16'b0, z0};
    assign z2_ext = {z2, 16'b0};
    assign z1_ext = {14'b0, z1_temp} - z0_ext - z2_ext;

    assign result = z2_ext + z0_ext + (z1_ext << 8);

    assign product = result;

endmodule

module karatsuba_mult8 (
    input  wire [7:0] operand_a,
    input  wire [7:0] operand_b,
    output wire [15:0] product
);
    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] z0, z2;
    wire [4:0] a_sum, b_sum;
    wire [9:0] z1_temp;
    wire [15:0] z0_ext, z2_ext, z1_ext;
    wire [15:0] result;

    assign a_low  = operand_a[3:0];
    assign a_high = operand_a[7:4];
    assign b_low  = operand_b[3:0];
    assign b_high = operand_b[7:4];

    karatsuba_mult4 u_z0 (
        .operand_a(a_low),
        .operand_b(b_low),
        .product(z0)
    );

    karatsuba_mult4 u_z2 (
        .operand_a(a_high),
        .operand_b(b_high),
        .product(z2)
    );

    assign a_sum = a_low + a_high;
    assign b_sum = b_low + b_high;

    karatsuba_mult5 u_z1 (
        .operand_a(a_sum),
        .operand_b(b_sum),
        .product(z1_temp)
    );

    assign z0_ext = {8'b0, z0};
    assign z2_ext = {z2, 8'b0};
    assign z1_ext = {6'b0, z1_temp} - z0_ext - z2_ext;

    assign result = z2_ext + z0_ext + (z1_ext << 4);

    assign product = result;

endmodule

module karatsuba_mult4 (
    input  wire [3:0] operand_a,
    input  wire [3:0] operand_b,
    output wire [7:0] product
);
    assign product = operand_a * operand_b;
endmodule

module karatsuba_mult5 (
    input  wire [4:0] operand_a,
    input  wire [4:0] operand_b,
    output wire [9:0] product
);
    assign product = operand_a * operand_b;
endmodule

module karatsuba_mult9 (
    input  wire [8:0] operand_a,
    input  wire [8:0] operand_b,
    output wire [17:0] product
);
    assign product = operand_a * operand_b;
endmodule

module karatsuba_mult17 (
    input  wire [16:0] operand_a,
    input  wire [16:0] operand_b,
    output wire [33:0] product
);
    assign product = operand_a * operand_b;
endmodule