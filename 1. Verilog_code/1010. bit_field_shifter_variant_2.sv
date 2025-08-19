//SystemVerilog
module bit_field_shifter(
    input  [31:0] data_in,
    input  [4:0]  field_start,   // LSB position of field
    input  [4:0]  field_width,   // Width of field (1-32)
    input  [4:0]  shift_amount,  // Amount to shift extracted field
    input         shift_dir,     // 0:right, 1:left
    output reg [31:0] data_out
);
    reg [31:0] extracted_field;
    reg [31:0] field_mask;
    reg [31:0] shifted_result;

    always @(*) begin
        // Generate field mask using case statement
        case (field_width)
            5'd0:   field_mask = 32'b0;
            5'd32:  field_mask = 32'hFFFFFFFF;
            default: field_mask = (32'h1 << field_width) - 1;
        endcase

        // Extract the bit field
        extracted_field = (data_in >> field_start) & field_mask;

        // Shift the extracted field using case statement
        case (shift_dir)
            1'b1: shifted_result = extracted_field << shift_amount;
            1'b0: shifted_result = extracted_field >> shift_amount;
            default: shifted_result = 32'b0;
        endcase

        data_out = shifted_result;
    end
endmodule