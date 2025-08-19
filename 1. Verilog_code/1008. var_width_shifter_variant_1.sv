//SystemVerilog
module var_width_shifter(
    input wire clk,
    input wire rst,
    input wire [31:0] data,
    input wire [1:0] width_sel,   // 00:8-bit, 01:16-bit, 10:24-bit, 11:32-bit
    input wire [4:0] shift_amt,
    input wire shift_left,
    output reg [31:0] result
);

    reg [31:0] masked_data;
    reg [31:0] left_stage0, left_stage1, left_stage2, left_stage3, left_stage4;
    reg [31:0] right_stage0, right_stage1, right_stage2, right_stage3, right_stage4;
    reg [31:0] shifter_result;

    always @(*) begin
        case (width_sel)
            2'b00: masked_data = {24'b0, data[7:0]};
            2'b01: masked_data = {16'b0, data[15:0]};
            2'b10: masked_data = {8'b0, data[23:0]};
            default: masked_data = data;
        endcase
    end

    // Left shift barrel shifter using if-else
    always @(*) begin
        if (shift_amt[0] == 1'b1)
            left_stage0 = {masked_data[30:0], 1'b0};
        else
            left_stage0 = masked_data;

        if (shift_amt[1] == 1'b1)
            left_stage1 = {left_stage0[29:0], 2'b0};
        else
            left_stage1 = left_stage0;

        if (shift_amt[2] == 1'b1)
            left_stage2 = {left_stage1[27:0], 4'b0};
        else
            left_stage2 = left_stage1;

        if (shift_amt[3] == 1'b1)
            left_stage3 = {left_stage2[23:0], 8'b0};
        else
            left_stage3 = left_stage2;

        if (shift_amt[4] == 1'b1)
            left_stage4 = {left_stage3[15:0], 16'b0};
        else
            left_stage4 = left_stage3;
    end

    // Right shift barrel shifter using if-else
    always @(*) begin
        if (shift_amt[0] == 1'b1)
            right_stage0 = {1'b0, masked_data[31:1]};
        else
            right_stage0 = masked_data;

        if (shift_amt[1] == 1'b1)
            right_stage1 = {2'b0, right_stage0[31:2]};
        else
            right_stage1 = right_stage0;

        if (shift_amt[2] == 1'b1)
            right_stage2 = {4'b0, right_stage1[31:4]};
        else
            right_stage2 = right_stage1;

        if (shift_amt[3] == 1'b1)
            right_stage3 = {8'b0, right_stage2[31:8]};
        else
            right_stage3 = right_stage2;

        if (shift_amt[4] == 1'b1)
            right_stage4 = {16'b0, right_stage3[31:16]};
        else
            right_stage4 = right_stage3;
    end

    // Select shifter result using if-else
    always @(*) begin
        if (shift_left == 1'b1)
            shifter_result = left_stage4;
        else
            shifter_result = right_stage4;
    end

    always @(posedge clk) begin
        if (rst)
            result <= 32'b0;
        else
            result <= shifter_result;
    end

endmodule