//SystemVerilog
module delay_ff #(
    parameter STAGES = 4  // 流水线级数
) (
    input  wire clk,      // 时钟输入
    input  wire rst_n,    // 复位信号
    input  wire d,        // 数据输入
    output wire q         // 数据输出
);

    // 使用单个寄存器数组存储所有流水线级
    // 这可以改善布局面积和电源路由
    reg [STAGES-1:0] pipeline_stages;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_stages <= {STAGES{1'b0}};
        end
        else begin
            // 移位寄存器操作
            pipeline_stages <= {pipeline_stages[STAGES-2:0], d};
        end
    end
    
    // 从数组最高位输出数据
    assign q = pipeline_stages[STAGES-1];

endmodule