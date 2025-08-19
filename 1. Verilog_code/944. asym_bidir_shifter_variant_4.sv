//SystemVerilog
module asym_bidir_shifter (
    input wire clk,          // 时钟信号
    input wire rst_n,        // 复位信号
    
    // 输入接口 - Valid-Ready协议
    input wire [15:0] data_in,
    input wire [3:0] l_shift,
    input wire [2:0] r_shift,
    input wire valid_in,     // 输入数据有效信号
    output reg ready_in,     // 输入就绪信号
    
    // 输出接口 - Valid-Ready协议
    output reg [15:0] data_out,
    output reg valid_out,    // 输出数据有效信号
    input wire ready_out     // 输出就绪信号
);

    // 流水线阶段寄存器
    reg [15:0] data_stage1, data_stage2;
    reg [3:0] l_shift_stage1, l_shift_stage2;
    reg [2:0] r_shift_stage1, r_shift_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    reg processing_stage1, processing_stage2, processing_stage3;
    
    // 计算中间结果的寄存器
    reg [15:0] left_shifted_data;
    reg [15:0] right_shifted_data;
    
    // 流水线阶段1：接收输入数据并进行左移操作准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 16'b0;
            l_shift_stage1 <= 4'b0;
            r_shift_stage1 <= 3'b0;
            valid_stage1 <= 1'b0;
            ready_in <= 1'b1;
            processing_stage1 <= 1'b0;
        end else begin
            // 输入握手
            if (ready_in && valid_in) begin
                data_stage1 <= data_in;
                l_shift_stage1 <= l_shift;
                r_shift_stage1 <= r_shift;
                valid_stage1 <= 1'b1;
                processing_stage1 <= 1'b1;
                ready_in <= 1'b0;
            end
            
            // 当阶段2准备好接收数据时
            if (processing_stage1 && !processing_stage2) begin
                valid_stage1 <= 1'b0;
                processing_stage1 <= 1'b0;
            end
            
            // 输出握手完成后重新启用输入接收
            if (valid_out && ready_out) begin
                ready_in <= 1'b1;
            end
        end
    end
    
    // 流水线阶段2：执行左移操作并准备右移操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 16'b0;
            l_shift_stage2 <= 4'b0;
            r_shift_stage2 <= 3'b0;
            left_shifted_data <= 16'b0;
            valid_stage2 <= 1'b0;
            processing_stage2 <= 1'b0;
        end else begin
            // 从阶段1接收数据
            if (valid_stage1 && !processing_stage2) begin
                data_stage2 <= data_stage1;
                l_shift_stage2 <= l_shift_stage1;
                r_shift_stage2 <= r_shift_stage1;
                valid_stage2 <= 1'b1;
                processing_stage2 <= 1'b1;
                
                // 执行左移操作
                left_shifted_data <= data_stage1 << l_shift_stage1;
            end
            
            // 当阶段3准备好接收数据时
            if (processing_stage2 && !processing_stage3) begin
                valid_stage2 <= 1'b0;
                processing_stage2 <= 1'b0;
            end
        end
    end
    
    // 流水线阶段3：执行右移操作并组合结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            right_shifted_data <= 16'b0;
            data_out <= 16'b0;
            valid_out <= 1'b0;
            processing_stage3 <= 1'b0;
        end else begin
            // 从阶段2接收数据
            if (valid_stage2 && !processing_stage3) begin
                // 执行右移操作
                right_shifted_data <= data_stage2 >> r_shift_stage2;
                processing_stage3 <= 1'b1;
            end
            
            // 组合左移和右移的结果
            if (processing_stage3) begin
                data_out <= left_shifted_data | right_shifted_data;
                valid_out <= 1'b1;
                processing_stage3 <= 1'b0;
            end
            
            // 输出握手
            if (valid_out && ready_out) begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule