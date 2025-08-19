//SystemVerilog
module p2s_buffer (
    input wire clk,
    input wire load,
    input wire shift,
    input wire [7:0] parallel_in,
    output reg serial_out
);
    // 第一级流水线 - 输入缓存
    reg [7:0] data_stage1;
    reg load_stage1, shift_stage1;
    
    // 第二级流水线 - 初始处理
    reg [7:0] data_stage2;
    reg load_stage2, shift_stage2;
    
    // 第三级流水线 - 数据处理前半部分
    reg [3:0] shift_reg_high_stage3;
    reg [3:0] shift_reg_low_stage3;
    reg serial_out_stage3;
    reg load_stage3, shift_stage3;
    reg high_active_stage3;  // 指示当前处理高位还是低位
    
    // 第四级流水线 - 数据处理后半部分
    reg [2:0] shift_reg_stage4;
    reg serial_out_stage4;
    reg shift_stage4;
    
    // 第五级流水线 - 输出准备
    reg serial_out_stage5;
    
    // 第一级流水线 - 输入缓存和控制信号同步
    always @(posedge clk) begin
        data_stage1 <= parallel_in;
        load_stage1 <= load;
        shift_stage1 <= shift;
    end
    
    // 第二级流水线 - 信号传递和进一步同步
    always @(posedge clk) begin
        data_stage2 <= data_stage1;
        load_stage2 <= load_stage1;
        shift_stage2 <= shift_stage1;
    end
    
    // 第三级流水线 - 数据拆分处理
    always @(posedge clk) begin
        load_stage3 <= load_stage2;
        shift_stage3 <= shift_stage2;
        
        if (load_stage2) begin
            shift_reg_high_stage3 <= data_stage2[7:4];
            shift_reg_low_stage3 <= data_stage2[3:0];
            serial_out_stage3 <= data_stage2[7];
            high_active_stage3 <= 1'b1;  // 从高位开始处理
        end else if (shift_stage2) begin
            if (high_active_stage3) begin
                // 处理高4位
                shift_reg_high_stage3 <= {shift_reg_high_stage3[2:0], 1'b0};
                serial_out_stage3 <= shift_reg_high_stage3[3];
                
                // 检查是否已经处理完高4位
                if (shift_reg_high_stage3[2:0] == 3'b0) begin
                    high_active_stage3 <= 1'b0;  // 下一次处理低位
                end
            end else begin
                // 处理低4位
                shift_reg_low_stage3 <= {shift_reg_low_stage3[2:0], 1'b0};
                serial_out_stage3 <= shift_reg_low_stage3[3];
            end
        end
    end
    
    // 第四级流水线 - 数据处理微调
    always @(posedge clk) begin
        serial_out_stage4 <= serial_out_stage3;
        shift_stage4 <= shift_stage3;
        
        if (load_stage3) begin
            shift_reg_stage4 <= shift_reg_high_stage3[2:0];
        end else if (shift_stage3) begin
            shift_reg_stage4 <= {shift_reg_stage4[1:0], 1'b0};
        end
    end
    
    // 第五级流水线 - 输出准备
    always @(posedge clk) begin
        serial_out_stage5 <= serial_out_stage4;
    end
    
    // 最终输出
    always @(posedge clk) begin
        serial_out <= serial_out_stage5;
    end
endmodule