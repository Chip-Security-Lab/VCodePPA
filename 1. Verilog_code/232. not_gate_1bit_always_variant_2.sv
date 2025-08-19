//SystemVerilog
module not_gate_1bit_always (
    input wire clk,       // 时钟信号
    input wire rst_n,     // 复位信号
    input wire A,         // 输入信号
    input wire en,        // 使能信号
    output reg Y,         // 输出信号
    input wire valid_in,  // 输入有效信号
    output wire ready_in, // 输入就绪信号
    output reg valid_out, // 输出有效信号
    input wire ready_out  // 输出就绪信号
);
    // 内部流水线寄存器
    reg stage1_data, stage2_data;
    reg stage1_valid, stage2_valid;
    
    // 流水线控制信号
    wire stage1_ready, stage2_ready;
    
    // 流水线就绪信号传递
    assign stage2_ready = ready_out || !stage2_valid;
    assign stage1_ready = stage2_ready || !stage1_valid;
    assign ready_in = stage1_ready;
    
    // 第一级流水线：捕获输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 1'b0;
            stage1_valid <= 1'b0;
        end else if (en && stage1_ready) begin
            stage1_data <= A;
            stage1_valid <= valid_in;
        end else if (stage1_ready && stage1_valid) begin
            stage1_valid <= 1'b0;
        end
    end
    
    // 第二级流水线：执行逻辑操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= 1'b0;
            stage2_valid <= 1'b0;
        end else if (en && stage2_ready) begin
            stage2_data <= ~stage1_data;
            stage2_valid <= stage1_valid;
        end else if (stage2_ready && stage2_valid) begin
            stage2_valid <= 1'b0;
        end
    end
    
    // 第三级流水线：输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
            valid_out <= 1'b0;
        end else if (en && ready_out) begin
            Y <= stage2_data;
            valid_out <= stage2_valid;
        end else if (ready_out && valid_out) begin
            valid_out <= 1'b0;
        end
    end
endmodule