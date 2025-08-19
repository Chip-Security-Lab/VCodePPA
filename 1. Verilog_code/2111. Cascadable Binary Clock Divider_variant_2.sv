//SystemVerilog
module binary_clk_divider(
    input clk_i,
    input rst_i,
    input enable_i,        // 流水线控制信号
    output [3:0] clk_div,  // 2^1, 2^2, 2^3, 2^4 division
    output valid_o         // 输出有效信号
);
    // 流水线寄存器组
    reg [3:0] div_stage1;
    reg [3:0] div_stage2;
    reg [3:0] div_stage3;
    
    // 流水线控制信号
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // 阶段1：增加计数器
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            div_stage1 <= 4'b0000;
            valid_stage1 <= 1'b0;
        end else if (enable_i) begin
            div_stage1 <= div_stage1 + 4'b0001;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 阶段2：中间流水线阶段
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            div_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end else if (enable_i) begin
            div_stage2 <= div_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3：输出流水线阶段
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            div_stage3 <= 4'b0000;
            valid_stage3 <= 1'b0;
        end else if (enable_i) begin
            div_stage3 <= div_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign clk_div = div_stage3;
    assign valid_o = valid_stage3;
endmodule