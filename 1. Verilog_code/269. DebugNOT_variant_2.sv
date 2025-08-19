//SystemVerilog
module DebugNOT(
    input wire clk,        
    input wire reset_n,    
    input wire [7:0] data,
    output reg [7:0] inverse,
    output reg parity      
);
    // 直接在输入端产生反相信号
    wire [7:0] inverse_comb;
    assign inverse_comb = ~data;
    
    // 计算奇偶校验
    wire parity_comb;
    assign parity_comb = ^inverse_comb;
    
    // 单流水线级 - 直接从组合逻辑获取结果并寄存
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            inverse <= 8'b0;
            parity <= 1'b0;
        end else begin
            inverse <= inverse_comb;
            parity <= parity_comb;
        end
    end
    
endmodule