//SystemVerilog
module DualRedundancyBridge(
    input clk, rst_n,
    input [31:0] data_a, data_b,
    output reg [31:0] data_out,
    output reg error
);
    // 预计算比较结果，减少关键路径延迟
    wire data_mismatch = |(data_a ^ data_b);
    
    // 寄存器复位逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error <= 1'b0;
            data_out <= 32'b0;
        end else begin
            error <= data_mismatch;
            if (data_mismatch) begin
                data_out <= 32'b0;
            end else begin
                data_out <= data_a;
            end
        end
    end
endmodule