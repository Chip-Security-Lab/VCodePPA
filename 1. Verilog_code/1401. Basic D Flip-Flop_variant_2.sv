//SystemVerilog
//IEEE 1364-2005 Verilog标准
module d_flip_flop (
    input wire clk,
    input wire rst_n,      // 复位信号
    input wire valid_in,   // 输入有效信号
    input wire d,          // 数据输入
    output wire valid_out, // 输出有效信号
    output wire q          // 数据输出
);
    // 流水线阶段1
    reg d_stage1;
    reg valid_stage1;
    
    // 流水线阶段2
    reg d_stage2;
    reg valid_stage2;
    
    // 增加流水线阶段3
    reg d_stage3;
    reg valid_stage3;
    
    // 增加流水线阶段4
    reg d_stage4;
    reg valid_stage4;
    
    // 流水线阶段1：捕获输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            d_stage1 <= d;
            valid_stage1 <= valid_in;
        end
    end
    
    // 流水线阶段2：第一级处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            d_stage2 <= d_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线阶段3：第二级处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            d_stage3 <= d_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 流水线阶段4：最终处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_stage4 <= 1'b0;
            valid_stage4 <= 1'b0;
        end else begin
            d_stage4 <= d_stage3;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // 输出赋值
    assign q = d_stage4;
    assign valid_out = valid_stage4;
    
endmodule