module ITRC_DoubleBuffer #(
    parameter WIDTH = 16
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] raw_status,
    output [WIDTH-1:0] stable_status
);
    reg [WIDTH-1:0] buf1, buf2;
    
    always @(posedge clk) begin
        if (!rst_n) {buf1, buf2} <= 0;
        else begin
            buf1 <= raw_status;
            buf2 <= buf1;  // 双缓冲同步
        end
    end
    
    assign stable_status = buf2;
endmodule