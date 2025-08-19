//SystemVerilog
// Top-level module: binary_to_bcd
module binary_to_bcd #(parameter WIDTH=8, DIGITS=3)(
    input wire [WIDTH-1:0] binary_in,
    output wire [4*DIGITS-1:0] bcd_out
);
    // Internal signals
    wire [4*DIGITS-1:0] bcd_converted;

    // Instantiate the BCD conversion controller
    bcd_convert_ctrl #(
        .WIDTH(WIDTH),
        .DIGITS(DIGITS)
    ) u_bcd_convert_ctrl (
        .ctrl_binary_in(binary_in),
        .ctrl_bcd_out(bcd_converted)
    );

    assign bcd_out = bcd_converted;

endmodule

//-----------------------------------------------------------------------------
// Submodule: bcd_convert_ctrl
// Description: Controls the iterative shift and add-3 process for binary to BCD
//-----------------------------------------------------------------------------
module bcd_convert_ctrl #(parameter WIDTH=8, DIGITS=3)(
    input  wire [WIDTH-1:0] ctrl_binary_in,
    output wire [4*DIGITS-1:0] ctrl_bcd_out
);
    integer bit_idx;
    reg [4*DIGITS-1:0] bcd_reg;
    reg [WIDTH-1:0] bin_reg;

    // Internal wire for the next BCD value after add-3
    wire [4*DIGITS-1:0] bcd_after_add3;
    reg  [4*DIGITS-1:0] bcd_add3_input;

    // Instantiate add3 logic for each digit
    genvar d;
    generate
        for (d = 0; d < DIGITS; d = d + 1) begin : GEN_ADD3
            wire [3:0] digit_in, digit_out;
            assign digit_in = bcd_add3_input[4*d +: 4];
            bcd_digit_add3 u_bcd_digit_add3 (
                .digit_in(digit_in),
                .digit_out(digit_out)
            );
            assign bcd_after_add3[4*d +: 4] = digit_out;
        end
    endgenerate

    // Iterative conversion process
    always @* begin
        bcd_reg = {4*DIGITS{1'b0}};
        bin_reg = ctrl_binary_in;
        for (bit_idx = 0; bit_idx < WIDTH; bit_idx = bit_idx + 1) begin
            // Prepare input for add3 for all digits
            bcd_add3_input = bcd_reg;
            // Apply add-3 to all digits in parallel
            bcd_reg = bcd_after_add3;
            // Shift left and bring in next binary bit
            bcd_reg = bcd_reg << 1;
            bcd_reg[0] = bin_reg[WIDTH-1];
            bin_reg = bin_reg << 1;
        end
    end

    assign ctrl_bcd_out = bcd_reg;

endmodule

//-----------------------------------------------------------------------------
// Submodule: bcd_digit_add3
// Description: Performs add-3 correction for a single BCD digit if needed
//-----------------------------------------------------------------------------
module bcd_digit_add3(
    input  wire [3:0] digit_in,
    output wire [3:0] digit_out
);
    // If digit is in range 5..9, add 3, else pass through
    assign digit_out = (digit_in >= 4'd5 && digit_in <= 4'd9) ? (digit_in + 4'd3) : digit_in;
endmodule