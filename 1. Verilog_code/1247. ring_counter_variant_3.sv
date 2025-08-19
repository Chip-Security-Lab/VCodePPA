//SystemVerilog
module ring_counter (
    input wire clock, reset,
    output reg [7:0] ring
);
    // 使用参数定义初始值和延迟级数
    localparam INIT_VALUE = 8'b10000000;
    localparam PIPELINE_STAGES = 4;
    
    // 使用单个寄存器数组替代多个单独寄存器
    reg [7:0] pipeline_regs [0:PIPELINE_STAGES-1];
    integer i;
    
    always @(posedge clock) begin
        if (reset) begin
            // 设置所有管道寄存器为初始值
            for (i = 0; i < PIPELINE_STAGES; i = i + 1)
                pipeline_regs[i] <= INIT_VALUE;
            ring <= INIT_VALUE;
        end
        else begin
            // 第一级管道处理环形移位
            pipeline_regs[0] <= {ring[0], ring[7:1]};
            
            // 其余管道级级联
            for (i = 1; i < PIPELINE_STAGES; i = i + 1)
                pipeline_regs[i] <= pipeline_regs[i-1];
                
            // 最终输出赋值
            ring <= pipeline_regs[PIPELINE_STAGES-1];
        end
    end
endmodule