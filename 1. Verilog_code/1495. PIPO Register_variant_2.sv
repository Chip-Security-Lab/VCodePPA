//SystemVerilog
module pipo_reg #(parameter DATA_WIDTH = 8) (
    input wire clock, reset, enable,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);
    // 查找表 - 用于辅助减法运算
    reg [DATA_WIDTH-1:0] lut_sub [0:255];
    
    // 增强的流水线阶段寄存器
    reg [DATA_WIDTH-1:0] stage1_data;
    reg [DATA_WIDTH-1:0] stage2_a_data;  // 添加中间流水线寄存器
    reg [DATA_WIDTH-1:0] stage2_result;
    reg valid_stage1, valid_stage1_a, valid_stage2;  // 增加中间有效信号
    
    // 查找表访问的中间结果
    wire [DATA_WIDTH-1:0] lut_access_result;
    
    // 初始化查找表
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            lut_sub[i] = 8'h00 - i[7:0]; // 预计算减法结果
        end
    end
    
    // 流水线阶段1：输入寄存
    always @(posedge clock) begin
        if (reset) begin
            stage1_data <= {DATA_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else if (enable) begin
            stage1_data <= data_in;
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 分配查找表访问结果到wire，减少组合路径
    assign lut_access_result = lut_sub[stage1_data];
    
    // 新增中间流水线阶段：切割查找表访问与结果处理
    always @(posedge clock) begin
        if (reset) begin
            stage2_a_data <= {DATA_WIDTH{1'b0}};
            valid_stage1_a <= 1'b0;
        end
        else if (enable) begin
            stage2_a_data <= lut_access_result;
            valid_stage1_a <= valid_stage1;
        end
        else begin
            valid_stage1_a <= 1'b0;
        end
    end
    
    // 流水线阶段2：处理查找表结果
    always @(posedge clock) begin
        if (reset) begin
            stage2_result <= {DATA_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else if (enable) begin
            stage2_result <= stage2_a_data;
            valid_stage2 <= valid_stage1_a;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 流水线阶段3：输出结果
    always @(posedge clock) begin
        if (reset) begin
            data_out <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end
        else if (enable) begin
            data_out <= stage2_result;
            valid_out <= valid_stage2;
        end
        else begin
            valid_out <= 1'b0;
        end
    end
endmodule