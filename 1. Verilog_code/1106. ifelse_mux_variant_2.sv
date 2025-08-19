//SystemVerilog
module ifelse_mux (
    input wire control,                  // Control signal
    input wire [3:0] path_a,             // Data path A (signed)
    input wire [3:0] path_b,             // Data path B (signed)
    output reg [7:0] mult_result,        // 4x4 signed multiplication result
    output reg [3:0] selected            // Output data path
);

    // Internal signals for mux output and multiplication operands
    wire [3:0] mux_output;
    reg [3:0] mux_output_reg;

    // Mux logic using if-else instead of conditional operator
    reg [3:0] mux_output_int;
    always @(*) begin : mux_logic_block
        if (control == 1'b0) begin
            mux_output_int = path_a;
        end else begin
            mux_output_int = path_b;
        end
    end
    assign mux_output = mux_output_int;

    // Register mux output for timing correctness
    always @(*) begin : mux_output_reg_block
        mux_output_reg = mux_output;
    end

    // Baugh-Wooley 4x4 signed multiplier instantiation
    wire [7:0] bw_mult_result;

    baugh_wooley_4x4_multiplier u_baugh_wooley_4x4_multiplier (
        .a(mux_output_reg),
        .b(path_b),
        .product(bw_mult_result)
    );

    // Register multiplier result for output
    always @(*) begin : mult_result_block
        mult_result = bw_mult_result;
    end

    // Output assignment for selected path (retains original MUX function)
    always @(*) begin : output_assign_block
        selected = mux_output_reg;
    end

endmodule

// Baugh-Wooley 4x4 signed multiplier module
module baugh_wooley_4x4_multiplier (
    input wire [3:0] a,           // signed 4-bit multiplicand
    input wire [3:0] b,           // signed 4-bit multiplier
    output reg [7:0] product      // signed 8-bit product
);

    // Partial products using if-else instead of conditional operator
    reg [3:0] pp0, pp1, pp2, pp3;

    always @(*) begin : partial_product_block
        if (a[0]) begin
            pp0 = b;
        end else begin
            pp0 = 4'b0000;
        end

        if (a[1]) begin
            pp1 = b;
        end else begin
            pp1 = 4'b0000;
        end

        if (a[2]) begin
            pp2 = b;
        end else begin
            pp2 = 4'b0000;
        end

        if (a[3]) begin
            pp3 = b;
        end else begin
            pp3 = 4'b0000;
        end
    end

    // Baugh-Wooley partial product modification
    wire [7:0] p0, p1, p2, p3;
    // Sign extension and bit inversion according to Baugh-Wooley

    // Replace conditional operator in sign extension/inversion logic
    reg b3_inv;
    always @(*) begin : b3_inv_block
        if (b[3]) begin
            b3_inv = 1'b0;
        end else begin
            b3_inv = 1'b1;
        end
    end

    assign p0 = {4'b0000, pp0};
    assign p1 = {3'b000, b3_inv, pp1};
    assign p2 = {2'b00, b3_inv, pp2, 1'b0};
    assign p3 = {1'b0, b3_inv, pp3, 2'b00};

    // Correction terms for Baugh-Wooley using if-else instead of conditional operator
    reg [4:0] corr_high;
    always @(*) begin : correction_high_block
        if (a[3] & b[3]) begin
            corr_high = 5'b11111;
        end else begin
            corr_high = 5'b00000;
        end
    end

    wire [7:0] correction;
    assign correction = {corr_high, 3'b000};

    // Final summation
    always @(*) begin
        product = p0 +
                  {p1[6:0], 1'b0} +
                  {p2[5:0], 2'b00} +
                  {p3[4:0], 3'b000} +
                  correction;
    end

endmodule