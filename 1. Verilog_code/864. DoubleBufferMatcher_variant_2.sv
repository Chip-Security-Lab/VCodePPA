//SystemVerilog
module DoubleBufferMatcher #(parameter WIDTH=8) (
    input clk, sel_buf,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern0, pattern1,
    output reg match
);

always @(posedge clk) begin
    if (sel_buf) begin
        match <= (data == pattern1);
    end else begin
        match <= (data == pattern0);
    end
end

endmodule