//SystemVerilog
module SyncMatcher #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] data_in, pattern,
    output reg match
);

reg [WIDTH-1:0] data_reg, pattern_reg;
wire match_next;

// 预计算比较结果
assign match_next = &(~(data_reg ^ pattern_reg));

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        match <= 1'b0;
        data_reg <= {WIDTH{1'b0}};
        pattern_reg <= {WIDTH{1'b0}};
    end
    else if (en) begin
        data_reg <= data_in;
        pattern_reg <= pattern;
        match <= match_next;
    end
end

endmodule