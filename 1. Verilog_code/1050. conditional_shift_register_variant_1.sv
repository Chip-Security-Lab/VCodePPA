//SystemVerilog
module conditional_shift_register #(
    parameter WIDTH = 8
) (
    input                  clk,
    input                  reset,
    input  [WIDTH-1:0]     parallel_in,
    input                  shift_in_bit,
    input  [1:0]           mode,         // 00=hold, 01=load, 10=shift right, 11=shift left
    input                  condition,    // Only perform operation if condition is true
    output [WIDTH-1:0]     parallel_out,
    output                 shift_out_bit
);

    reg [WIDTH-1:0] shift_reg_main;
    reg [WIDTH-1:0] shift_reg_buf1;
    reg [WIDTH-1:0] shift_reg_buf2;

    // 2-bit subtraction result lookup table
    wire [1:0] sub_lut_out;
    reg  [1:0] sub_lut_a;
    reg  [1:0] sub_lut_b;
    subtractor_lut2 sub_lut_inst (
        .a(sub_lut_a),
        .b(sub_lut_b),
        .diff(sub_lut_out)
    );

    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_reg_main <= {WIDTH{1'b0}};
        end else if (condition) begin
            case (mode)
                2'b01: shift_reg_main <= parallel_in;
                2'b10: begin
                    // Shift right, use LUT-based subtractor for the two LSBs
                    shift_reg_main[WIDTH-1] <= shift_in_bit;
                    if (WIDTH >= 2) begin
                        // Use LUT subtractor for the two LSBs
                        sub_lut_a <= {shift_in_bit, shift_reg_main[WIDTH-1]};
                        sub_lut_b <= 2'b00; // No borrow for shift
                        shift_reg_main[1:0] <= sub_lut_out;
                        // Direct shift for other bits
                        for (i = 2; i < WIDTH; i = i + 1) begin
                            shift_reg_main[i] <= shift_reg_main[i-1];
                        end
                    end else begin
                        // For WIDTH == 1
                        sub_lut_a <= {shift_in_bit, shift_reg_main[0]};
                        sub_lut_b <= 2'b00;
                        shift_reg_main[0] <= sub_lut_out[0];
                    end
                end
                2'b11: shift_reg_main <= {shift_reg_main[WIDTH-2:0], shift_in_bit};
                default: shift_reg_main <= shift_reg_main;
            endcase
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            shift_reg_buf1 <= {WIDTH{1'b0}};
        else
            shift_reg_buf1 <= shift_reg_main;
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            shift_reg_buf2 <= {WIDTH{1'b0}};
        else
            shift_reg_buf2 <= shift_reg_buf1;
    end

    assign parallel_out = shift_reg_buf2;
    assign shift_out_bit = (mode == 2'b10) ? shift_reg_buf2[0] : shift_reg_buf2[WIDTH-1];

endmodule

module subtractor_lut2 (
    input  [1:0] a,
    input  [1:0] b,
    output [1:0] diff
);
    reg [1:0] diff_lut [0:15];
    initial begin
        diff_lut[ 0] = 2'b00; // 0-0
        diff_lut[ 1] = 2'b11; // 0-1
        diff_lut[ 2] = 2'b10; // 0-2
        diff_lut[ 3] = 2'b01; // 0-3
        diff_lut[ 4] = 2'b01; // 1-0
        diff_lut[ 5] = 2'b00; // 1-1
        diff_lut[ 6] = 2'b11; // 1-2
        diff_lut[ 7] = 2'b10; // 1-3
        diff_lut[ 8] = 2'b10; // 2-0
        diff_lut[ 9] = 2'b01; // 2-1
        diff_lut[10] = 2'b00; // 2-2
        diff_lut[11] = 2'b11; // 2-3
        diff_lut[12] = 2'b11; // 3-0
        diff_lut[13] = 2'b10; // 3-1
        diff_lut[14] = 2'b01; // 3-2
        diff_lut[15] = 2'b00; // 3-3
    end
    assign diff = diff_lut[{a, b}];
endmodule