//SystemVerilog
module shift_max_detect #(parameter W=8) (
    input clk,
    input [W-1:0] din,
    output reg [$clog2(W)-1:0] max_shift
);
    reg [W-1:0] din_reg;
    reg [$clog2(W)-1:0] min_index;
    integer index_counter;

    // Pipeline Stage 1: Register input
    always @(posedge clk) begin
        din_reg <= din;
    end

    // Pipeline Stage 2: Find minimum index of '1'
    always @(posedge clk) begin
        min_index = W-1;
        index_counter = 0;
        while (index_counter < W) begin
            if (din_reg[index_counter] == 1'b1 && index_counter < min_index) begin
                min_index = index_counter[$clog2(W)-1:0];
            end
            index_counter = index_counter + 1;
        end
        max_shift <= min_index;
    end
endmodule