//SystemVerilog
module multi_shadow_reg #(
    parameter WIDTH = 8,
    parameter LEVELS = 3
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire capture,
    input wire [1:0] shadow_select,
    output wire [WIDTH-1:0] shadow_out
);
    // 流水线级寄存器
    reg [WIDTH-1:0] main_reg_stage1;
    reg [WIDTH-1:0] main_reg_stage2;
    
    // 多个影子寄存器 - 分级存储
    reg [WIDTH-1:0] shadow_reg_stage1 [0:LEVELS-1];
    reg [WIDTH-1:0] shadow_reg_stage2 [0:LEVELS-1];
    
    // 流水线控制信号
    reg capture_stage1, capture_stage2;
    reg [1:0] select_stage1, select_stage2;
    
    // 第一级流水线 - 数据捕获
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            main_reg_stage1 <= 0;
            capture_stage1 <= 0;
            select_stage1 <= 0;
        end else begin
            main_reg_stage1 <= data_in;
            capture_stage1 <= capture;
            select_stage1 <= shadow_select;
        end
    end
    
    // 第二级流水线 - 数据处理和影子寄存器更新准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            main_reg_stage2 <= 0;
            capture_stage2 <= 0;
            select_stage2 <= 0;
        end else begin
            main_reg_stage2 <= main_reg_stage1;
            capture_stage2 <= capture_stage1;
            select_stage2 <= select_stage1;
        end
    end
    
    // 影子寄存器更新 - 使用流水线阶段
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < LEVELS; i = i + 1) begin
                shadow_reg_stage1[i] <= 0;
                shadow_reg_stage2[i] <= 0;
            end
        end else begin
            // 第一级影子寄存器更新逻辑
            if (capture_stage1) begin
                shadow_reg_stage1[0] <= main_reg_stage1;
                for (i = 1; i < LEVELS; i = i + 1)
                    shadow_reg_stage1[i] <= shadow_reg_stage2[i-1];
            end
            
            // 第二级影子寄存器更新 - 传递到下一级
            for (i = 0; i < LEVELS; i = i + 1)
                shadow_reg_stage2[i] <= shadow_reg_stage1[i];
        end
    end
    
    // 输出选择逻辑 - 使用最新的选择信号
    reg [WIDTH-1:0] shadow_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out_reg <= 0;
        else
            shadow_out_reg <= shadow_reg_stage2[select_stage2];
    end
    
    assign shadow_out = shadow_out_reg;
endmodule