//SystemVerilog
module DualBufRecovery #(parameter WIDTH=8) (
    input clk, async_rst,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] buf1, buf2;
    reg [WIDTH-1:0] partial_result1, partial_result2, partial_result3;
    
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            buf1 <= 0;
            buf2 <= 0;
            partial_result1 <= 0;
            partial_result2 <= 0;
            partial_result3 <= 0;
            dout <= 0;
        end
        else begin
            // First stage: capture inputs with minimal logic
            buf1 <= din;
            buf2 <= buf1;
            
            // Pipeline stage 1: compute all partial results in parallel
            // Split the original complex final computation into balanced paths
            partial_result1 <= buf1 & buf2;
            partial_result2 <= buf1 & din;
            partial_result3 <= buf2 & din;
            
            // Pipeline stage 2: balanced final output computation
            // Using separate OR operations to balance the critical path
            dout <= partial_result1 | partial_result2 | partial_result3;
        end
    end
endmodule