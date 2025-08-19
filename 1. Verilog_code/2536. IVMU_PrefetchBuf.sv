module IVMU_PrefetchBuf #(parameter DEPTH=2) (
    input clk,
    input [31:0] vec_in,
    output reg [31:0] vec_out
);
    reg [31:0] buffer [0:DEPTH-1];
    integer i;
    
    always @(posedge clk) begin
        // 移动缓冲区
        for (i = DEPTH-1; i > 0; i = i - 1) begin
            buffer[i] <= buffer[i-1];
        end
        buffer[0] <= vec_in;
        vec_out <= buffer[DEPTH-1];
    end
endmodule