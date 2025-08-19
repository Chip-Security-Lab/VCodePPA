//SystemVerilog
// Top-level 4-to-1 multiplexer with Booth multiplier instances
module mux_4to1_case (
    input wire [1:0] sel,                 // 2-bit selection lines
    input wire [7:0] in0, in1, in2, in3,  // Data inputs
    output reg [7:0] data_out             // Output data
);

    wire [7:0] booth_in0, booth_in1, booth_in2, booth_in3;

    // Booth multiplier instances for each input
    booth_multiplier_8bit booth_mult0 (
        .multiplicand(in0),
        .multiplier(8'd1),
        .product(booth_in0)
    );

    booth_multiplier_8bit booth_mult1 (
        .multiplicand(in1),
        .multiplier(8'd1),
        .product(booth_in1)
    );

    booth_multiplier_8bit booth_mult2 (
        .multiplicand(in2),
        .multiplier(8'd1),
        .product(booth_in2)
    );

    booth_multiplier_8bit booth_mult3 (
        .multiplicand(in3),
        .multiplier(8'd1),
        .product(booth_in3)
    );

    // Always block: 4-to-1 multiplexer logic
    // Selects the output from one of the Booth multipliers based on 'sel'
    always @(*) begin
        case(sel)
            2'b00: data_out = booth_in0;
            2'b01: data_out = booth_in1;
            2'b10: data_out = booth_in2;
            2'b11: data_out = booth_in3;
            default: data_out = 8'd0;
        endcase
    end

endmodule

// 8-bit Booth multiplier module with restructured always blocks
module booth_multiplier_8bit (
    input  wire [7:0] multiplicand,
    input  wire [7:0] multiplier,
    output reg  [7:0] product
);

    // Internal registers for Booth algorithm
    reg signed [15:0] booth_accum;
    reg signed [8:0]  booth_multiplicand_ext;
    reg signed [8:0]  booth_multiplier_ext;
    reg [16:0]        booth_temp;
    integer           i;

    // Always block: Extend and initialize multiplicand and multiplier
    // Handles sign extension and preparation for Booth algorithm
    always @(*) begin : booth_extend_init
        booth_multiplicand_ext = {multiplicand[7], multiplicand};
        booth_multiplier_ext   = {multiplier, 1'b0};
    end

    // Always block: Initialize accumulator and booth_temp
    // Sets up the accumulator and intermediate variable
    always @(*) begin : booth_init
        booth_accum = 16'd0;
        booth_temp = {8'd0, booth_multiplier_ext};
    end

    // Always block: Booth algorithm core calculation
    // Performs Booth encoding and accumulation
    always @(*) begin : booth_calculation
        reg signed [15:0] accum_temp;
        reg [16:0] temp_var;
        accum_temp = booth_accum;
        temp_var = booth_temp;
        for (i = 0; i < 8; i = i + 1) begin
            case (temp_var[1:0])
                2'b01: accum_temp = accum_temp + (booth_multiplicand_ext <<< i);
                2'b10: accum_temp = accum_temp - (booth_multiplicand_ext <<< i);
                default: ;
            endcase
            temp_var = temp_var >> 1;
        end
        // Assign the result to the output
        product = accum_temp[7:0];
    end

endmodule