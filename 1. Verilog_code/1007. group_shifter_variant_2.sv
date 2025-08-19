//SystemVerilog
module group_shifter(
    input clk,
    input reset,
    input [31:0] data_in,
    input [1:0] group_count,  // Number of 4-bit groups to shift
    input dir,                // 1:left, 0:right
    output reg [31:0] data_out
);

    wire [31:0] left_shift_stage0, left_shift_stage1;
    wire [31:0] right_shift_stage0, right_shift_stage1;
    wire [1:0] shift_amt;

    assign shift_amt = group_count;

    // Left barrel shifter
    assign left_shift_stage0 = shift_amt[0] ? {data_in[27:0], 4'b0000} : data_in;
    assign left_shift_stage1 = shift_amt[1] ? {left_shift_stage0[23:0], 8'b00000000} : left_shift_stage0;

    // Right barrel shifter
    assign right_shift_stage0 = shift_amt[0] ? {4'b0000, data_in[31:4]} : data_in;
    assign right_shift_stage1 = shift_amt[1] ? {8'b00000000, right_shift_stage0[31:8]} : right_shift_stage0;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 32'h0;
        end else begin
            if (dir) begin
                data_out <= left_shift_stage1;
            end else begin
                data_out <= right_shift_stage1;
            end
        end
    end

endmodule