//SystemVerilog
// Top-level module: binary_to_bcd_hier
module binary_to_bcd_hier #(parameter WIDTH=8, DIGITS=3)(
    input wire [WIDTH-1:0] binary_in,
    output wire [4*DIGITS-1:0] bcd_out
);
    // Internal signals
    wire [4*DIGITS-1:0] bcd_result;

    // Instantiate the BCD conversion controller
    binary_to_bcd_controller #(
        .WIDTH(WIDTH),
        .DIGITS(DIGITS)
    ) u_bcd_controller (
        .binary_in (binary_in),
        .bcd_out   (bcd_result)
    );

    assign bcd_out = bcd_result;
endmodule

// -----------------------------------------------------------------------------
// BCD Controller Module
// Controls the overall BCD conversion process using submodules
// -----------------------------------------------------------------------------
module binary_to_bcd_controller #(parameter WIDTH=8, DIGITS=3)(
    input wire [WIDTH-1:0] binary_in,
    output reg [4*DIGITS-1:0] bcd_out
);
    integer i;
    reg [4*DIGITS-1:0] bcd_reg;
    reg [WIDTH-1:0] bin_reg;

    // Iteration variables for the process
    integer digit_idx;

    // Temporary signals for digit adjustment
    wire [3:0] digit_in [0:DIGITS-1];
    wire [3:0] digit_adj [0:DIGITS-1];

    genvar k;
    generate
        for (k = 0; k < DIGITS; k = k + 1) begin : GEN_BCD_DIGIT
            assign digit_in[k] = bcd_reg[4*k +: 4];
            // Instantiate BCD digit adjuster for each digit
            bcd_digit_adjust u_digit_adjust (
                .digit_in  (digit_in[k]),
                .digit_out (digit_adj[k])
            );
        end
    endgenerate

    // BCD conversion logic using double-dabble algorithm
    always @* begin
        bcd_reg = {4*DIGITS{1'b0}};
        bin_reg = binary_in;
        i = 0;
        while (i < WIDTH) begin
            // Adjust each BCD digit if necessary
            for (digit_idx = 0; digit_idx < DIGITS; digit_idx = digit_idx + 1) begin
                if (bcd_reg[4*digit_idx +: 4] > 4)
                    bcd_reg[4*digit_idx +: 4] = digit_adj[digit_idx];
            end
            // Shift left and bring in the next binary bit
            bcd_reg = bcd_reg << 1;
            bcd_reg[0] = bin_reg[WIDTH-1];
            bin_reg = bin_reg << 1;
            i = i + 1;
        end
        bcd_out = bcd_reg;
    end
endmodule

// -----------------------------------------------------------------------------
// BCD Digit Adjuster Module
// Adds 3 to a BCD digit if it is greater than 4
// -----------------------------------------------------------------------------
module bcd_digit_adjust(
    input  wire [3:0] digit_in,
    output wire [3:0] digit_out
);
    // If digit_in > 4, add 3, else pass through
    assign digit_out = (digit_in > 4) ? (digit_in + 3) : digit_in;
endmodule