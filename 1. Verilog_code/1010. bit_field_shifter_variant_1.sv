//SystemVerilog
module bit_field_shifter(
    input  [31:0] data_in,
    input  [4:0]  field_start,   // LSB position of field
    input  [4:0]  field_width,   // Width of field (1-32)
    input  [4:0]  shift_amount,  // Amount to shift extracted field
    input         shift_dir,     // 0:right, 1:left
    output reg [31:0] data_out
);

    reg [31:0] field_mask;
    reg [31:0] extracted;
    reg [31:0] shifted_left;
    reg [31:0] shifted_right;

    // Barrel shifter for right shift (32-bit, variable amount)
    function [31:0] barrel_shifter_right;
        input [31:0] value;
        input [4:0]  shift_amt;
        reg   [31:0] stage [0:5];
        integer i;
        begin
            stage[0] = value;
            stage[1] = shift_amt[0] ? {1'b0, stage[0][31:1]}   : stage[0];
            stage[2] = shift_amt[1] ? {2'b0, stage[1][31:2]}   : stage[1];
            stage[3] = shift_amt[2] ? {4'b0, stage[2][31:4]}   : stage[2];
            stage[4] = shift_amt[3] ? {8'b0, stage[3][31:8]}   : stage[3];
            stage[5] = shift_amt[4] ? {16'b0, stage[4][31:16]} : stage[4];
            barrel_shifter_right = stage[5];
        end
    endfunction

    // Barrel shifter for left shift (32-bit, variable amount)
    function [31:0] barrel_shifter_left;
        input [31:0] value;
        input [4:0]  shift_amt;
        reg   [31:0] stage [0:5];
        integer i;
        begin
            stage[0] = value;
            stage[1] = shift_amt[0] ? {stage[0][30:0], 1'b0}   : stage[0];
            stage[2] = shift_amt[1] ? {stage[1][29:0], 2'b0}   : stage[1];
            stage[3] = shift_amt[2] ? {stage[2][27:0], 4'b0}   : stage[2];
            stage[4] = shift_amt[3] ? {stage[3][23:0], 8'b0}   : stage[3];
            stage[5] = shift_amt[4] ? {stage[4][15:0], 16'b0}  : stage[4];
            barrel_shifter_left = stage[5];
        end
    endfunction

    always @(*) begin
        // Create the mask for the bit field
        if (field_width == 0) begin
            field_mask = 32'b0;
        end else if (field_width >= 32) begin
            field_mask = 32'hFFFFFFFF;
        end else begin
            field_mask = (32'h1 << field_width) - 1;
        end

        // Extract the bit field using barrel shifter for right shift
        extracted = barrel_shifter_right(data_in, field_start) & field_mask;

        // Shift the extracted field using barrel shifters
        shifted_left  = barrel_shifter_left(extracted, shift_amount);
        shifted_right = barrel_shifter_right(extracted, shift_amount);

        data_out = shift_dir ? shifted_left : shifted_right;
    end

endmodule