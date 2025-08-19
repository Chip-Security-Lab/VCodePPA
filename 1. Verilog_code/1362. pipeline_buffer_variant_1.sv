//SystemVerilog
//==============================================================================
//==============================================================================
module pipeline_buffer (
    input  wire        clk,      // 系统时钟
    input  wire [15:0] data_in,  // 输入数据
    input  wire        valid_in, // 输入有效信号
    output reg  [15:0] data_out, // 输出数据
    output reg         valid_out // 输出有效信号
);

    //--------------------------------------------------------------------------
    // 流水线级级定义 - 每级使用专用命名区分数据传输阶段
    //--------------------------------------------------------------------------
    // 第一级流水线寄存器
    reg [15:0] pipe_stage1_data;
    reg        pipe_stage1_valid;
    
    // 第二级流水线寄存器
    reg [15:0] pipe_stage2_data;
    reg        pipe_stage2_valid;
    
    //--------------------------------------------------------------------------
    // 流水线数据传输控制
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        // 第一级流水线 - 输入捕获阶段
        pipe_stage1_data  <= data_in;
        pipe_stage1_valid <= valid_in;
        
        // 第二级流水线 - 中间处理阶段
        pipe_stage2_data  <= pipe_stage1_data;
        pipe_stage2_valid <= pipe_stage1_valid;
        
        // 输出级 - 最终输出阶段
        data_out  <= pipe_stage2_data;
        valid_out <= pipe_stage2_valid;
    end

endmodule