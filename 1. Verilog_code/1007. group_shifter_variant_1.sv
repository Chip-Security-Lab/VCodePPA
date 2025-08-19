//SystemVerilog
module group_shifter(
    input clk, reset,
    input [31:0] data_in,
    input [1:0] group_count,  // Number of 4-bit groups to shift
    input dir,                // 1:left, 0:right
    output reg [31:0] data_out
);
    wire [4:0] bit_shift = {group_count, 2'b00};  // Multiply by 4
    always @(posedge clk) begin
        if (reset)
            data_out <= 32'h0;
        else
            data_out <= dir ? (data_in << bit_shift) : (data_in >> bit_shift);
    end
endmodule