//SystemVerilog
module int_ctrl_edge #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] async_intr,
    output reg [WIDTH-1:0] synced_intr
);

    // 用于捕捉上一个周期的中断状态
    reg [WIDTH-1:0] intr_ff;
    
    // 查找表辅助减法器实现
    reg [255:0] lut_complement; // 8位取反的查找表
    reg [WIDTH-1:0] complement_result;
    
    // 初始化查找表
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            lut_complement[i] = ~i[7:0];
        end
    end
    
    // 查找表取反实现
    always @(*) begin
        for (i = 0; i < WIDTH; i = i + 1) begin
            complement_result[i] = lut_complement[intr_ff[i] ? 8'h01 : 8'h00];
        end
    end
    
    // 时序逻辑优化：分离重置逻辑和主逻辑，避免不必要的连接操作
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_ff <= {WIDTH{1'b0}};
            synced_intr <= {WIDTH{1'b0}};
        end
        else begin
            intr_ff <= async_intr;
            // 优化比较链：使用查找表生成的取反值进行上升沿检测
            synced_intr <= async_intr & complement_result;
        end
    end

endmodule