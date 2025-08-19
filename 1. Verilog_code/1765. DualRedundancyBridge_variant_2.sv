//SystemVerilog
module DualRedundancyBridge(
    input clk, rst_n,
    input [31:0] data_a, data_b,
    output reg [31:0] data_out,
    output reg error
);
    // 优化比较逻辑以减少延迟
    wire data_mismatch = (data_a !== data_b);
    
    // 使用异步复位以提高可靠性
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error <= 1'b0;
            data_out <= 32'b0;
        end else begin
            // 直接使用比较结果进行赋值
            error <= data_mismatch;
            data_out <= (data_mismatch) ? 32'b0 : data_a;
        end
    end
endmodule