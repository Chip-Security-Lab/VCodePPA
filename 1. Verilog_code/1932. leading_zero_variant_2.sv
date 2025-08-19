//SystemVerilog
module leading_zero #(parameter DW=8) (
    input  [DW-1:0] data,
    output reg [$clog2(DW+1)-1:0] count
);
    integer idx;
    wire [DW-1:0] one_vector;
    wire [DW-1:0] data_inverted;
    wire [DW-1:0] adder_sum;
    wire         carry_in;
    wire         carry_out;

    assign one_vector = {DW{1'b1}};
    assign data_inverted = ~data;
    assign carry_in = 1'b1; // For subtraction: data - 0

    assign {carry_out, adder_sum} = data + data_inverted + carry_in;

    always @* begin
        count = DW;
        idx = DW-1;
        while (idx >= 0) begin
            if (adder_sum[idx]) count = DW-1 - idx;
            idx = idx - 1;
        end
    end
endmodule