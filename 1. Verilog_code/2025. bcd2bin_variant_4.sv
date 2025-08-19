//SystemVerilog
// Top-level module: BCD to Binary Converter (Hierarchical Structure)
module bcd2bin (
    input        clk,
    input        enable,
    input  [7:0] bcd_in,
    output [6:0] bin_out
);

    wire [3:0] tens_digit;
    wire [3:0] units_digit;
    wire [6:0] tens_times_ten;
    wire [6:0] sum_result;

    // Splitter: Extracts tens and units digits from BCD input
    bcd_splitter u_bcd_splitter (
        .bcd_in      (bcd_in),
        .tens_digit  (tens_digit),
        .units_digit (units_digit)
    );

    // Multiplier: Multiplies tens digit by 10
    bcd_multiplier_by10_opt u_bcd_multiplier_by10 (
        .digit_in   (tens_digit),
        .product_out(tens_times_ten)
    );

    // Adder: Adds tens*10 and units digit
    bcd_adder_opt u_bcd_adder (
        .a          (tens_times_ten),
        .b          (units_digit),
        .sum        (sum_result)
    );

    // Output register: Registers the binary output on posedge clk when enabled
    bcd_output_reg u_bcd_output_reg (
        .clk        (clk),
        .enable     (enable),
        .data_in    (sum_result),
        .data_out   (bin_out)
    );

endmodule

//------------------------------------------------------------------------------
// Submodule: bcd_splitter
// Function: Extracts tens and units digits from an 8-bit BCD input
//------------------------------------------------------------------------------
module bcd_splitter (
    input  [7:0] bcd_in,
    output [3:0] tens_digit,
    output [3:0] units_digit
);
    assign tens_digit  = bcd_in[7:4];
    assign units_digit = bcd_in[3:0];
endmodule

//------------------------------------------------------------------------------
// Submodule: bcd_multiplier_by10_opt
// Function: Multiplies a 4-bit digit by 10 (for BCD tens place), optimized
//------------------------------------------------------------------------------
module bcd_multiplier_by10_opt (
    input  [3:0] digit_in,
    output reg [6:0] product_out
);
    always @(*) begin
        // Only valid BCD digits (0-9) are allowed, so use case for optimal synthesis
        case (digit_in)
            4'd0: product_out = 7'd0;
            4'd1: product_out = 7'd10;
            4'd2: product_out = 7'd20;
            4'd3: product_out = 7'd30;
            4'd4: product_out = 7'd40;
            4'd5: product_out = 7'd50;
            4'd6: product_out = 7'd60;
            4'd7: product_out = 7'd70;
            4'd8: product_out = 7'd80;
            4'd9: product_out = 7'd90;
            default: product_out = 7'd0;
        endcase
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: bcd_adder_opt
// Function: Adds two values (tens*10 and units) to get binary output, optimized
//------------------------------------------------------------------------------
module bcd_adder_opt (
    input  [6:0] a,
    input  [3:0] b,
    output reg [6:0] sum
);
    always @(*) begin
        // BCD units digit is always 0-9; if not, output zero for safety
        if (b <= 4'd9)
            sum = a + b;
        else
            sum = 7'd0;
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: bcd_output_reg
// Function: Registers the final binary output on clk posedge when enabled
//------------------------------------------------------------------------------
module bcd_output_reg (
    input        clk,
    input        enable,
    input  [6:0] data_in,
    output reg [6:0] data_out
);
    always @(posedge clk) begin
        if (enable)
            data_out <= data_in;
    end
endmodule