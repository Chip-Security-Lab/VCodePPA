//SystemVerilog
module sipo_register #(parameter N = 16) (
    input wire clock, reset, enable, serial_in,
    output wire [N-1:0] parallel_out
);
    // 主数据寄存器
    reg [N-1:0] data_reg_stage1;
    reg [N-1:0] data_reg_stage2;
    reg [N-1:0] data_reg_stage3;
    
    // 流水线中间结果寄存器
    reg serial_in_stage1, serial_in_stage2;
    reg enable_stage1, enable_stage2;
    reg [7:0] low_byte_stage1, low_byte_stage2;
    reg [N-9:0] high_byte_stage1, high_byte_stage2;
    reg low_byte_msb_stage1, low_byte_msb_stage2;
    reg [7:0] lut_result_stage1, lut_result_stage2;
    
    // 查找表定义
    reg [7:0] lut_values [0:1];
    
    // 初始化查找表
    initial begin
        lut_values[0] = 8'h00;
        lut_values[1] = 8'h01;
    end
    
    // 流水线阶段1：捕获输入和初步处理
    always @(posedge clock) begin
        if (reset) begin
            serial_in_stage1 <= 1'b0;
            enable_stage1 <= 1'b0;
            data_reg_stage1 <= {N{1'b0}};
        end else begin
            serial_in_stage1 <= serial_in;
            enable_stage1 <= enable;
            data_reg_stage1 <= data_reg_stage3; // 反馈最终结果
        end
    end
    
    // 流水线阶段2：查找表操作和数据准备
    always @(posedge clock) begin
        if (reset) begin
            serial_in_stage2 <= 1'b0;
            enable_stage2 <= 1'b0;
            low_byte_stage1 <= 8'h0;
            high_byte_stage1 <= {(N-8){1'b0}};
            lut_result_stage1 <= 8'h0;
            low_byte_msb_stage1 <= 1'b0;
        end else begin
            serial_in_stage2 <= serial_in_stage1;
            enable_stage2 <= enable_stage1;
            
            if (N > 8) begin
                // 将数据分成高字节和低字节处理
                low_byte_stage1 <= data_reg_stage1[7:0];
                high_byte_stage1 <= data_reg_stage1[N-1:8];
                low_byte_msb_stage1 <= data_reg_stage1[7];
                
                // 使用查找表辅助移位计算
                lut_result_stage1 <= {data_reg_stage1[6:0], lut_values[serial_in_stage1]};
            end else begin
                // 对于N<=8的情况，直接计算结果
                lut_result_stage1 <= {data_reg_stage1[N-2:0], lut_values[serial_in_stage1]};
            end
        end
    end
    
    // 流水线阶段3：最终处理和数据更新
    always @(posedge clock) begin
        if (reset) begin
            low_byte_stage2 <= 8'h0;
            high_byte_stage2 <= {(N-8){1'b0}};
            lut_result_stage2 <= 8'h0;
            low_byte_msb_stage2 <= 1'b0;
            data_reg_stage2 <= {N{1'b0}};
            data_reg_stage3 <= {N{1'b0}};
        end else begin
            // 传递阶段2的数据
            low_byte_stage2 <= low_byte_stage1;
            high_byte_stage2 <= high_byte_stage1;
            lut_result_stage2 <= lut_result_stage1;
            low_byte_msb_stage2 <= low_byte_msb_stage1;
            
            // 最终数据组装
            if (enable_stage2) begin
                if (N > 8) begin
                    data_reg_stage2 <= {high_byte_stage2[N-9:0], low_byte_msb_stage2, lut_result_stage2};
                end else begin
                    data_reg_stage2 <= lut_result_stage2[N-1:0];
                end
            end else begin
                data_reg_stage2 <= data_reg_stage3;
            end
            
            // 输出阶段
            data_reg_stage3 <= data_reg_stage2;
        end
    end
    
    // 输出赋值
    assign parallel_out = data_reg_stage3;
endmodule