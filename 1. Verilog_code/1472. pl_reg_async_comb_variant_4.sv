//SystemVerilog
module pl_reg_async_comb #(parameter W=4) (
    input clk, arst, load,
    input [W-1:0] din,
    output [W-1:0] dout
);
    // 流水线阶段信号
    wire [W-1:0] stage1_wire;
    reg [W-1:0] stage2_reg;
    reg [W-1:0] stage3_reg;
    
    // 流水线控制信号
    wire stage1_valid_wire;
    reg stage2_valid, stage3_valid;
    
    // 前向重定时：移除第一级寄存器，转为组合逻辑
    assign stage1_wire = din;
    assign stage1_valid_wire = load;
    
    // 第二级流水线 - 现在捕获输入数据
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            stage2_reg <= 0;
            stage2_valid <= 0;
        end else begin
            stage2_reg <= stage1_wire;
            stage2_valid <= stage1_valid_wire;
        end
    end
    
    // 第三级流水线
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            stage3_reg <= 0;
            stage3_valid <= 0;
        end else begin
            stage3_reg <= stage2_reg;
            stage3_valid <= stage2_valid;
        end
    end
    
    // 输出赋值
    assign dout = stage3_reg;
    
endmodule