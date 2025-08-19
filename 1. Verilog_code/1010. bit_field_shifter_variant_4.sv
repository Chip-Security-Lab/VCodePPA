//SystemVerilog
module bit_field_shifter(
    input  [31:0] data_in,
    input  [4:0]  field_start,   // LSB position of field
    input  [4:0]  field_width,   // Width of field (1-32)
    input  [4:0]  shift_amount,  // Amount to shift extracted field
    input         shift_dir,     // 0:right, 1:left
    output reg [31:0] data_out
);
    reg [31:0] extracted;
    reg [31:0] shifted_result;

    // Signed multiplication optimized (Booth's algorithm - iterative, 32-bit, 1-cycle)
    function [31:0] signed_mult32;
        input signed [31:0] a;
        input signed [31:0] b;
        reg signed [63:0] product;
        integer i;
        begin
            product = 64'sd0;
            for (i = 0; i < 32; i = i + 1) begin
                product = b[i] ? product + (a <<< i) : product;
            end
            signed_mult32 = product[31:0];
        end
    endfunction

    always @(*) begin
        extracted = (data_in >> field_start) & ((32'h1 << field_width) - 1);
        shifted_result = shift_dir
            ? signed_mult32($signed({1'b0, extracted}), $signed(32'h1 << shift_amount))
            : (extracted >> shift_amount);
        data_out = shifted_result;
    end
endmodule