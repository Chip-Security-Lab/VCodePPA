//SystemVerilog
module BiDir_XNOR(
    inout  [7:0] bus_a,
    inout  [7:0] bus_b,
    input        dir,
    input        clk,        // 添加时钟信号用于流水线
    input        rst_n,      // 添加复位信号
    output [7:0] result
);
    // 内部信号声明 - 增强数据流可视性
    reg  [7:0] bus_a_reg, bus_b_reg;       // 输入寄存器级
    reg  [7:0] xnor_stage1;                // 第一级流水线
    reg  [7:0] xnor_result_pipelined;      // 第二级流水线
    wire [7:0] xnor_combinational;         // 组合逻辑结果
    reg        dir_reg;                    // 寄存方向控制信号
    
    // 输入寄存 - 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_a_reg <= 8'h0;
            bus_b_reg <= 8'h0;
            dir_reg   <= 1'b0;
        end else begin
            bus_a_reg <= bus_a;
            bus_b_reg <= bus_b;
            dir_reg   <= dir;
        end
    end
    
    // 组合逻辑 XNOR 计算
    assign xnor_combinational = bus_a_reg ~^ bus_b_reg;
    
    // 第二级流水线 - XNOR结果寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_stage1 <= 8'h0;
        end else begin
            xnor_stage1 <= xnor_combinational;
        end
    end
    
    // 第三级流水线 - 最终结果寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_result_pipelined <= 8'h0;
        end else begin
            xnor_result_pipelined <= xnor_stage1;
        end
    end
    
    // 输出三态缓冲器控制 - 使用流水线输出
    assign bus_a = dir_reg ? xnor_result_pipelined : 8'hzz;
    assign bus_b = dir_reg ? 8'hzz : xnor_result_pipelined;
    
    // 结果输出
    assign result = xnor_result_pipelined;
    
endmodule