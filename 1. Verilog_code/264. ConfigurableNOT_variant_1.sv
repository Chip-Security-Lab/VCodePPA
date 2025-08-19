//SystemVerilog
module ConfigurableNOT(
    input logic        clk,     // 添加时钟信号用于流水线寄存
    input logic        rst_n,   // 添加复位信号
    input logic        pol,     // 极性控制
    input logic [7:0]  in,      // 数据输入
    output logic [7:0] out      // 数据输出
);
    // 定义流水线寄存器
    logic [7:0] in_reg;           // 输入数据寄存
    logic pol_reg;                // 极性控制寄存
    logic [7:0] inverted_data;    // 反相数据
    logic [7:0] out_comb;         // 组合逻辑输出
    
    // 第一级流水线：寄存输入数据和控制信号
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_reg <= 8'h0;
            pol_reg <= 1'b0;
        end else begin
            in_reg <= in;
            pol_reg <= pol;
        end
    end
    
    // 第二级：数据处理 - 通过组合逻辑实现反相功能
    assign inverted_data = ~in_reg;
    
    // 第三级：数据选择 - 根据极性选择输出数据
    assign out_comb = pol_reg ? inverted_data : in_reg;
    
    // 第四级流水线：寄存输出数据
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h0;
        end else begin
            out <= out_comb;
        end
    end
    
endmodule