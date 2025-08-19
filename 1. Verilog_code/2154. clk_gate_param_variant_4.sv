//SystemVerilog
module clk_gate_param #(parameter DW=8, AW=4) (
    input wire clk, en,
    input wire [AW-1:0] addr,
    output reg [DW-1:0] data
);

    // 声明内部时钟门控信号
    wire gated_clk;
    
    // 使用专用时钟门控单元实现低功耗时钟门控
    reg en_latch;
    always @(*) begin
        if (!clk)
            en_latch = en;
    end
    assign gated_clk = clk & en_latch;
    
    // 流水线寄存器以切割关键路径
    reg [AW-1:0] addr_reg;
    reg [DW-1:0] shifted_data_stage1;
    reg en_reg;
    
    // 第一级流水线：捕获输入信号
    always @(posedge clk) begin
        addr_reg <= addr;
        en_reg <= en;
    end
    
    // 减少组合逻辑深度的方法，将操作分解为两个阶段
    // 第二级流水线：计算部分结果
    always @(posedge clk) begin
        if (en_reg)
            shifted_data_stage1 <= {addr_reg, 2'b00};
        else
            shifted_data_stage1 <= {DW{1'b0}};
    end
    
    // 最终输出寄存器
    always @(posedge clk) begin
        if (!en)
            data <= {DW{1'b0}};
        else
            data <= shifted_data_stage1;
    end

endmodule