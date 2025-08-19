//SystemVerilog
module neg_edge_siso #(parameter DEPTH = 4) (
    input wire clk_n, arst_n, sin,
    output wire sout
);
    // 定义双寄存器，提高时序稳定性
    reg [DEPTH-1:0] sr_array;
    
    // 使用非阻塞赋值确保正确时序
    // 采用有效利用负边沿触发的方式
    always @(negedge clk_n, negedge arst_n) begin
        if (!arst_n) begin
            // 优化复位路径，明确指定每个位的复位值
            sr_array <= {DEPTH{1'b0}};
        end else begin
            // 优化移位操作，使用拼接运算提高综合工具理解
            sr_array <= {sr_array[DEPTH-2:0], sin};
        end
    end
    
    // 直接从寄存器访问输出位，减少额外逻辑
    assign sout = sr_array[DEPTH-1];
endmodule