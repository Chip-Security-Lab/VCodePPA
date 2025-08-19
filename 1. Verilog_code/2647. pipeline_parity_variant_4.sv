//SystemVerilog
module pipeline_parity (
    input clk,
    input [63:0] data,
    output reg parity
);
    // 内部寄存器
    reg [63:0] stage1_data;
    reg stage2_parity;
    
    // 合并的流水线处理
    always @(posedge clk) begin
        // 第一阶段：数据寄存
        stage1_data <= data;
        
        // 第二阶段：计算校验位
        stage2_parity <= ^stage1_data;
        
        // 第三阶段：输出寄存
        parity <= stage2_parity;
    end
endmodule