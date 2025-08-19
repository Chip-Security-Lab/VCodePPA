//SystemVerilog
module transparent_buffer (
    input  wire        clk,        // 时钟信号
    input  wire        rst_n,      // 复位信号，低电平有效
    input  wire [7:0]  data_in,    // 输入数据
    input  wire        enable,     // 使能信号
    output wire [7:0]  data_out    // 输出数据
);

    // 数据流水线寄存器
    reg [7:0] data_pipeline_r;
    reg       enable_pipeline_r;
    
    // 第一级流水线 - 捕获输入数据和控制信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_pipeline_r   <= 8'b0;
            enable_pipeline_r <= 1'b0;
        end else begin
            data_pipeline_r   <= data_in;
            enable_pipeline_r <= enable;
        end
    end
    
    // 第二级流水线 - 输出驱动逻辑
    // 使用三态逻辑以保持原始功能特性
    assign data_out = enable_pipeline_r ? data_pipeline_r : 8'bz;

endmodule