//SystemVerilog
module enabled_pattern_compare #(parameter DWIDTH = 8) (
    input clk, rst_n, en,
    input [DWIDTH-1:0] in_data, in_pattern,
    output reg match
);
    reg [DWIDTH-1:0] diff;
    reg [DWIDTH:0] borrow;
    integer i;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            match <= 1'b0;
        end
        else if (en) begin
            // 借位减法器算法实现
            borrow[0] = 1'b0;
            for (i = 0; i < DWIDTH; i = i + 1) begin
                diff[i] = in_data[i] ^ in_pattern[i] ^ borrow[i];
                borrow[i+1] = (~in_data[i] & in_pattern[i]) | (~in_data[i] & borrow[i]) | (in_pattern[i] & borrow[i]);
            end
            match <= (diff == {DWIDTH{1'b0}} && borrow[DWIDTH] == 1'b0);
        end
    end
endmodule