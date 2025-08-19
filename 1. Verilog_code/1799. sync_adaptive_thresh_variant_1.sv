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
    reg [DW-1:0] threshold_reg;
    wire [DW-1:0] threshold_next;
    wire comp_result;
    
    // 预计算阈值，减少关键路径延迟
    assign threshold_next = background + sensitivity;
    
    // 使用专门的比较器逻辑
    assign comp_result = (signal_in > threshold_reg);
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            threshold_reg <= {DW{1'b0}};
            out_bit <= 1'b0;
        end
        else begin
            threshold_reg <= threshold_next;
            out_bit <= comp_result;
        end
    end
endmodule