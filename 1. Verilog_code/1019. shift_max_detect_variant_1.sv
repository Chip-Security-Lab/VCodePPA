//SystemVerilog
module shift_max_detect #(parameter W=8) (
    input clk,
    input [W-1:0] din,
    output reg [$clog2(W)-1:0] max_shift
);
    reg [W-1:0] din_reg;
    reg [$clog2(W)-1:0] max_shift_comb;
    integer i;

    // Register the input first (forward retiming)
    always @(posedge clk) begin
        din_reg <= din;
    end

    // Combinational logic operates on registered input
    always @* begin
        max_shift_comb = W-1;
        for (i = 0; i < W; i = i + 1) begin
            if (din_reg[i] == 1'b1 && i < max_shift_comb) begin
                max_shift_comb = i;
            end
        end
    end

    // Register the output after the combinational logic
    always @(posedge clk) begin
        max_shift <= max_shift_comb;
    end
endmodule