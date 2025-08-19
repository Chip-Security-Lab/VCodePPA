//SystemVerilog
module nor3_register (
    input wire [7:0] input_A, input_B, input_C,
    output wire [7:0] output_Y
);
    wire [7:0] or_stage1, or_stage2;
    wire [15:0] booth_prod1, booth_prod2;

    // Booth multiplier instances
    booth_multiplier_8bit booth_mul_inst1 (
        .multiplicand(input_A),
        .multiplier(input_B),
        .product(booth_prod1)
    );

    booth_multiplier_8bit booth_mul_inst2 (
        .multiplicand(or_stage1),
        .multiplier(input_C),
        .product(booth_prod2)
    );

    assign or_stage1 = input_A | input_B;
    assign or_stage2 = or_stage1 | input_C;
    assign output_Y = ~or_stage2;

endmodule

module booth_multiplier_8bit (
    input  wire [7:0] multiplicand,
    input  wire [7:0] multiplier,
    output reg  [15:0] product
);
    reg [15:0] extended_multiplicand;
    reg [8:0]  extended_multiplier;
    reg [15:0] accumulator;
    integer idx;

    // Extend multiplicand sign
    always @(*) begin
        extended_multiplicand = { {8{multiplicand[7]}}, multiplicand };
    end

    // Extend multiplier and zero LSB
    always @(*) begin
        extended_multiplier = {multiplier, 1'b0};
    end

    // Booth multiplication accumulation
    always @(*) begin
        accumulator = 16'b0;
        for (idx = 0; idx < 8; idx = idx + 1) begin
            if      ({extended_multiplier[idx+1], extended_multiplier[idx]} == 2'b01) begin
                accumulator = accumulator + (extended_multiplicand << idx);
            end else if ({extended_multiplier[idx+1], extended_multiplier[idx]} == 2'b10) begin
                accumulator = accumulator - (extended_multiplicand << idx);
            end else begin
                accumulator = accumulator;
            end
        end
    end

    // Assign product output
    always @(*) begin
        product = accumulator;
    end
endmodule