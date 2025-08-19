//SystemVerilog
//IEEE 1364-2005 (SystemVerilog)
module param_d_register #(
    parameter WIDTH = 8,
    parameter RESET_VALUE = {WIDTH{1'b0}},  // 可配置的复位值
    parameter PIPELINE_STAGES = 2          // 可配置的流水线级数
) (
    input  wire              clk,          // 时钟信号
    input  wire              rst_n,        // 低电平有效复位
    input  wire [WIDTH-1:0]  d,            // 数据输入
    output reg  [WIDTH-1:0]  q             // 数据输出
);
    // 定义流水线寄存器数组 - 清晰表示数据流路径
    reg [WIDTH-1:0] pipeline_regs [0:PIPELINE_STAGES-1];
    
    // 第一级流水线 - 数据输入缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pipeline_regs[0] <= RESET_VALUE;
        else
            pipeline_regs[0] <= d;
    end
    
    // 生成中间流水线级
    genvar i;
    generate
        for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin : pipeline_stage
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    pipeline_regs[i] <= RESET_VALUE;
                else
                    pipeline_regs[i] <= pipeline_regs[i-1];
            end
        end
    endgenerate
    
    // 最终数据输出路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= RESET_VALUE;
        else
            q <= pipeline_regs[PIPELINE_STAGES-1];
    end
    
endmodule