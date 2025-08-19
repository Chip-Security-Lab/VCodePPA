//SystemVerilog
module sync_adaptive_thresh #(
    parameter DW = 8
)(
    input clk, rst,
    input [DW-1:0] signal_in,
    input [DW-1:0] background,
    input [DW-1:0] sensitivity,
    output reg out_bit
);
    reg [DW-1:0] threshold;
    
    // 在时序逻辑中计算threshold，提高时序性能
    always @(posedge clk or posedge rst) begin
        if (rst)
            threshold <= 0;
        else
            threshold <= background + sensitivity;
    end
    
    // 使用if-else结构替代条件运算符
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_bit <= 1'b0;
        end else begin
            if (signal_in > threshold) begin
                out_bit <= 1'b1;
            end else begin
                out_bit <= 1'b0;
            end
        end
    end
endmodule