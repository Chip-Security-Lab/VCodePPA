//SystemVerilog
module bidir_shifter(
    input clk, reset_n,
    input [7:0] data_in,
    input [2:0] shift_amount,
    input left_right_n,    // 1=left, 0=right
    input arithmetic_n,    // 1=arithmetic, 0=logical (right only)
    output reg [7:0] data_out
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            data_out <= 8'h00;
        else if (left_right_n)
            data_out <= data_in << shift_amount;
        else if (arithmetic_n && data_in[7])
            data_out <= (data_in >> shift_amount) | (~({8{1'b1}} >> shift_amount));
        else
            data_out <= data_in >> shift_amount;
    end
endmodule