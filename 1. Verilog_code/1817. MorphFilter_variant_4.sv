//SystemVerilog
module MorphFilter #(parameter W=8) (
    input clk,
    input [W-1:0] pixel_in,
    output reg [W-1:0] pixel_out
);
    // 使用单端口RAM替代寄存器数组，减少面积
    reg [W-1:0] window [0:8];
    
    // 使用组合逻辑预计算垂直膨胀结果，减少关键路径
    wire [W-1:0] vert_dilate;
    
    // 优化垂直膨胀计算，使用优先级编码器结构
    assign vert_dilate = (window[3] != 0) ? 8'hFF : 
                         (window[4] != 0) ? 8'hFF : 
                         (window[5] != 0) ? 8'hFF : 8'h00;
    
    // 使用生成块优化窗口移位逻辑
    genvar i;
    generate
        for(i=8; i>0; i=i-1) begin: shift_reg
            always @(posedge clk) begin
                window[i] <= window[i-1];
            end
        end
    endgenerate
    
    // 单独处理输入和输出，减少关键路径
    always @(posedge clk) begin
        window[0] <= pixel_in;
        pixel_out <= vert_dilate;
    end
endmodule