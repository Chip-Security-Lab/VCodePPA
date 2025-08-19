//SystemVerilog
module tristate_buffer (
    input wire clk,                // 时钟信号
    input wire rst_n,              // 低电平有效复位信号
    input wire [15:0] data_in,     // 输入数据
    input wire oe,                 // 输出使能
    output reg [15:0] data_out     // 输出数据
);
    // 流水线级 1: 输入寄存
    reg [15:0] data_stage1;
    reg oe_stage1;
    
    // 流水线级 2: 中间处理阶段1
    reg [15:0] data_stage2;
    reg oe_stage2;
    
    // 流水线级 3: 中间处理阶段2
    reg [15:0] data_stage3;
    reg oe_stage3;
    
    // 流水线级 4: 控制逻辑准备
    reg [15:0] data_stage4;
    reg oe_stage4;
    
    // 流水线级 5: 最终控制逻辑
    reg [15:0] data_stage5;
    reg oe_stage5;
    
    // 输入流水线阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 16'b0;
            oe_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            oe_stage1 <= oe;
        end
    end
    
    // 中间流水线阶段1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 16'b0;
            oe_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            oe_stage2 <= oe_stage1;
        end
    end
    
    // 中间流水线阶段2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= 16'b0;
            oe_stage3 <= 1'b0;
        end else begin
            data_stage3 <= data_stage2;
            oe_stage3 <= oe_stage2;
        end
    end
    
    // 中间流水线阶段3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage4 <= 16'b0;
            oe_stage4 <= 1'b0;
        end else begin
            data_stage4 <= data_stage3;
            oe_stage4 <= oe_stage3;
        end
    end
    
    // 流水线控制逻辑阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage5 <= 16'b0;
            oe_stage5 <= 1'b0;
        end else begin
            data_stage5 <= data_stage4;
            oe_stage5 <= oe_stage4;
        end
    end
    
    // 输出级 - 三态逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'bz;
        end else begin
            data_out <= oe_stage5 ? data_stage5 : 16'bz;
        end
    end
    
endmodule