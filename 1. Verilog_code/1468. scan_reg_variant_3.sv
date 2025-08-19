//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

module scan_reg(
    input wire clk,
    input wire rst_n,
    input wire [7:0] parallel_data,
    input wire scan_in,
    input wire scan_en,
    input wire load,
    output wire [7:0] data_out,
    output wire scan_out
);
    // 流水线阶段1 - 操作选择与数据预处理
    reg [1:0] op_select_stage1;
    reg [7:0] parallel_data_stage1;
    reg scan_in_stage1;
    reg [7:0] data_out_stage1;
    reg valid_stage1;
    
    // 流水线阶段2 - 数据处理
    reg [1:0] op_select_stage2;
    reg [7:0] parallel_data_stage2;
    reg scan_in_stage2;
    reg [7:0] data_out_stage2;
    reg valid_stage2;
    
    // 流水线阶段3 - 输出映射
    reg [7:0] data_out_stage3;
    
    // 流水线阶段1: 输入捕获和操作判断
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op_select_stage1 <= 2'b00;
            parallel_data_stage1 <= 8'b0;
            scan_in_stage1 <= 1'b0;
            data_out_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end else begin
            // 确定操作类型
            casez({rst_n, scan_en, load})
                3'b0??: op_select_stage1 <= 2'b00; // 复位操作
                3'b10?: op_select_stage1 <= 2'b01; // 扫描操作
                3'b101: op_select_stage1 <= 2'b10; // 加载操作
                3'b100: op_select_stage1 <= 2'b11; // 保持当前值
            endcase
            
            // 缓存输入数据
            parallel_data_stage1 <= parallel_data;
            scan_in_stage1 <= scan_in;
            data_out_stage1 <= data_out_stage3;  // 反馈当前输出值
            valid_stage1 <= 1'b1;
        end
    end
    
    // 流水线阶段2: 数据处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op_select_stage2 <= 2'b00;
            parallel_data_stage2 <= 8'b0;
            scan_in_stage2 <= 1'b0;
            data_out_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            // 传递控制信号
            op_select_stage2 <= op_select_stage1;
            parallel_data_stage2 <= parallel_data_stage1;
            scan_in_stage2 <= scan_in_stage1;
            data_out_stage2 <= data_out_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线阶段3: 最终输出计算和寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage3 <= 8'b0;
        end else if (valid_stage2) begin
            // 根据操作码选择下一个数据状态
            case (op_select_stage2)
                2'b00: data_out_stage3 <= 8'b0;                             // 复位操作
                2'b01: data_out_stage3 <= {data_out_stage2[6:0], scan_in_stage2}; // 扫描操作
                2'b10: data_out_stage3 <= parallel_data_stage2;             // 加载操作
                2'b11: data_out_stage3 <= data_out_stage2;                  // 保持当前值
            endcase
        end
    end
    
    // 输出连接
    assign data_out = data_out_stage3;
    assign scan_out = data_out_stage3[7];

endmodule

`default_nettype wire