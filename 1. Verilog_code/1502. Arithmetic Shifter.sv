module arith_shifter #(parameter WIDTH = 8) (
    input wire clk, rst, shift_en,
    input wire [WIDTH-1:0] data_in,
    input wire [2:0] shift_amt,
    output reg [WIDTH-1:0] result
);
    always @(posedge clk) begin
        if (rst)
            result <= 0;
        else if (shift_en)
            result <= $signed(data_in) >>> shift_amt;
    end
endmodule