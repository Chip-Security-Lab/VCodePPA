module bit_field_shifter(
    input [31:0] data_in,
    input [4:0] field_start,  // LSB position of field
    input [4:0] field_width,  // Width of field (1-32)
    input [4:0] shift_amount, // Amount to shift extracted field
    input shift_dir,          // 0:right, 1:left
    output reg [31:0] data_out
);
    reg [31:0] extracted;
    always @(*) begin
        // Extract the bit field
        extracted = (data_in >> field_start) & ((1 << field_width) - 1);
        // Shift the extracted field
        data_out = shift_dir ? (extracted << shift_amount) : (extracted >> shift_amount);
    end
endmodule