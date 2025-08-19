//SystemVerilog
module or_gate_8input_8bit (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    input wire [7:0] d,
    input wire [7:0] e,
    input wire [7:0] f,
    input wire [7:0] g,
    input wire [7:0] h,
    output wire [7:0] y
);
    // 使用时钟使能信号以降低功耗
    reg clk_en;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_en <= 1'b1;
        else
            clk_en <= ~clk_en;  // 降低时钟频率，减少切换功耗
    end
    
    // 采用局部参数来提高代码可读性和可维护性
    localparam RESET_VALUE = 8'h0;
    
    // 优化第一级流水线 - 减少关键路径并行合并
    reg [7:0] stage1_or1, stage1_or2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_or1 <= RESET_VALUE;
            stage1_or2 <= RESET_VALUE;
        end 
        else if (clk_en) begin
            // 直接在寄存器赋值中计算或逻辑，减少中间组合逻辑级数
            stage1_or1 <= (a | b) | (c | d);
            stage1_or2 <= (e | f) | (g | h);
        end
    end
    
    // 优化第二级流水线 - 单一寄存器
    reg [7:0] result;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= RESET_VALUE;
        end 
        else if (clk_en) begin
            result <= stage1_or1 | stage1_or2;
        end
    end
    
    // 输出赋值
    assign y = result;
    
endmodule