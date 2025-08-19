//SystemVerilog
module p2s_buffer (
    input wire clk,
    input wire rst_n,  // 添加复位信号
    input wire load,
    input wire shift,
    input wire [7:0] parallel_in,
    output wire serial_out,
    output wire ready,  // 新增ready信号表示可以接收新数据
    input wire valid_in,  // 新增valid信号表示输入数据有效
    output wire valid_out  // 新增valid_out信号表示输出数据有效
);
    // 流水线寄存器
    reg [7:0] stage1_data;
    reg [6:0] stage2_shift_reg;
    reg stage2_serial_out_reg;
    
    // 流水线控制信号
    reg stage1_valid;
    reg stage2_valid;
    reg [2:0] bit_counter;  // 跟踪已发送位数
    
    // 第一级流水线 - 数据加载阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 8'b0;
            stage1_valid <= 1'b0;
        end
        else if (load && valid_in && ready) begin
            stage1_data <= parallel_in;
            stage1_valid <= 1'b1;
        end
        else if (shift && stage2_valid && bit_counter == 3'd7) begin
            stage1_valid <= 1'b0;  // 数据全部发送完毕
        end
    end
    
    // 第二级流水线 - 位移和串行输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_shift_reg <= 7'b0;
            stage2_serial_out_reg <= 1'b0;
            stage2_valid <= 1'b0;
            bit_counter <= 3'b0;
        end
        else if (stage1_valid && !stage2_valid) begin
            // 从第一级加载数据
            stage2_shift_reg <= stage1_data[6:0];
            stage2_serial_out_reg <= stage1_data[7];
            stage2_valid <= 1'b1;
            bit_counter <= 3'b0;
        end
        else if (shift && stage2_valid) begin
            if (bit_counter < 3'd7) begin
                // 正常位移操作
                stage2_serial_out_reg <= stage2_shift_reg[6];
                stage2_shift_reg <= {stage2_shift_reg[5:0], 1'b0};
                bit_counter <= bit_counter + 1'b1;
            end
            else begin
                // 最后一位已处理完毕
                bit_counter <= 3'b0;
                if (!stage1_valid) begin
                    stage2_valid <= 1'b0;  // 没有更多数据要处理
                end
                else begin
                    // 如果第一级有新数据，立即加载
                    stage2_shift_reg <= stage1_data[6:0];
                    stage2_serial_out_reg <= stage1_data[7];
                end
            end
        end
    end
    
    // 输出逻辑
    assign serial_out = stage2_serial_out_reg;
    assign valid_out = stage2_valid;
    assign ready = !stage1_valid || (stage2_valid && shift && bit_counter == 3'd7);
    
endmodule