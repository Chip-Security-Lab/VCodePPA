//SystemVerilog
module delayed_write_buffer (
    input wire clk,
    input wire rst,  // 添加复位信号
    input wire [15:0] data_in,
    input wire trigger,
    input wire ready_in,  // 添加输入就绪信号
    output wire ready_out, // 添加输出就绪信号
    output wire valid_out, // 添加数据有效信号
    output reg [15:0] data_out
);
    // 流水线阶段寄存器和控制信号
    reg [15:0] buffer_stage1;
    reg [15:0] buffer_stage2;
    reg valid_stage1;
    reg valid_stage2;
    
    // 第一级流水线 - 输入捕获阶段
    always @(posedge clk) begin
        if (rst) begin
            buffer_stage1 <= 16'b0;
            valid_stage1 <= 1'b0;
        end else if (ready_out) begin
            if (trigger) begin
                buffer_stage1 <= data_in;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 第二级流水线 - 处理阶段
    always @(posedge clk) begin
        if (rst) begin
            buffer_stage2 <= 16'b0;
            valid_stage2 <= 1'b0;
        end else if (ready_out) begin
            buffer_stage2 <= buffer_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 输出阶段
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 16'b0;
        end else if (ready_out && valid_stage2) begin
            data_out <= buffer_stage2;
        end
    end
    
    // 流水线控制逻辑
    assign ready_out = ready_in || !valid_stage2; // 如果下游准备好接收或当前没有有效数据，则准备好接收新数据
    assign valid_out = valid_stage2; // 输出数据有效信号
    
endmodule