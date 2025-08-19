//SystemVerilog
module polar_to_rect #(parameter WIDTH=16, LUT_SIZE=16)(
    input wire [WIDTH-1:0] magnitude,
    input wire [WIDTH-1:0] angle, // 0-255表示0-2π
    output reg [WIDTH-1:0] x_out,
    output reg [WIDTH-1:0] y_out
);

    reg signed [WIDTH-1:0] cos_lut [0:LUT_SIZE-1];
    reg signed [WIDTH-1:0] sin_lut [0:LUT_SIZE-1];
    reg [WIDTH-1:0] lut_index;

    // 8-bit subtraction LUT for A - B
    reg [7:0] sub_lut [0:65535];
    integer sub_lut_init_idx;
    integer lut_init_idx;

    // Subtraction variables
    reg [7:0] sub_a_in;
    reg [7:0] sub_b_in;
    reg [7:0] sub_result;

    // Internal wires for angle LUT indexing
    wire [7:0] angle_lut_index;

    initial begin
        // Initialize cosine and sine LUTs
        lut_init_idx = 0;
        while (lut_init_idx < LUT_SIZE) begin
            cos_lut[lut_init_idx] = $cos(2.0*3.14159*lut_init_idx/LUT_SIZE) * (1 << (WIDTH-2));
            sin_lut[lut_init_idx] = $sin(2.0*3.14159*lut_init_idx/LUT_SIZE) * (1 << (WIDTH-2));
            lut_init_idx = lut_init_idx + 1;
        end

        // Initialize subtraction LUT: sub_lut[{A,B}] = A - B
        for (sub_lut_init_idx = 0; sub_lut_init_idx < 65536; sub_lut_init_idx = sub_lut_init_idx + 1) begin
            sub_lut[sub_lut_init_idx] = (sub_lut_init_idx[15:8]) - (sub_lut_init_idx[7:0]);
        end
    end

    // Function: LUT-based 8-bit subtractor
    function [7:0] lut_sub_8b;
        input [7:0] a;
        input [7:0] b;
        begin
            lut_sub_8b = sub_lut[{a, b}];
        end
    endfunction

    // Map angle to LUT index
    assign angle_lut_index = (angle * LUT_SIZE) >> 8;

    always @* begin
        // Use LUT-based subtractor for demonstration (e.g. angle - 0)
        sub_a_in = angle[7:0];
        sub_b_in = 8'd0;
        sub_result = lut_sub_8b(sub_a_in, sub_b_in);
        lut_index = angle_lut_index;

        x_out = (magnitude * cos_lut[lut_index]) >> (WIDTH-2);
        y_out = (magnitude * sin_lut[lut_index]) >> (WIDTH-2);
    end

endmodule