//SystemVerilog
module shift_max_detect #(parameter W=8) (
    input clk,
    input [W-1:0] din,
    output reg [$clog2(W)-1:0] max_shift
);
    reg [W-1:0] din_reg;
    reg [$clog2(W)-1:0] max_shift_next;
    integer i;

    always @(posedge clk) begin
        din_reg <= din;

        max_shift_next = W-1;
        for (i = 0; i < W; i = i + 1) begin
            if (din_reg[i] == 1'b1 && i < max_shift_next) begin
                max_shift_next = i;
            end
        end

        max_shift <= max_shift_next;
    end
endmodule