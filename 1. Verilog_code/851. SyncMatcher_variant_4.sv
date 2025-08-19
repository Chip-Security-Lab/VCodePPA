//SystemVerilog
module SyncMatcher #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] data_in, pattern,
    output reg match
);

// Internal signals
reg [WIDTH-1:0] data_reg, pattern_reg;
wire [WIDTH-1:0] data_next, pattern_next;
wire match_next;

// Combinational logic
assign data_next = en ? data_in : data_reg;
assign pattern_next = en ? pattern : pattern_reg;
assign match_next = &(~(data_reg ^ pattern_reg));

// Sequential logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        match <= 1'b0;
        data_reg <= {WIDTH{1'b0}};
        pattern_reg <= {WIDTH{1'b0}};
    end
    else begin
        data_reg <= data_next;
        pattern_reg <= pattern_next;
        match <= match_next;
    end
end

endmodule