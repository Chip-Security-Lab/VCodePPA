module bank_pattern_matcher #(parameter W = 8, BANKS = 4) (
    input clk, rst_n,
    input [W-1:0] data,
    input [W-1:0] patterns [BANKS-1:0],
    input [$clog2(BANKS)-1:0] bank_sel,
    output reg match
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match <= 1'b0;
        else
            match <= (data == patterns[bank_sel]);
    end
endmodule