//SystemVerilog
module or_gate_3input_4bit (
    input  wire        clk,      // 添加时钟信号用于流水线寄存器
    input  wire        rst_n,    // 添加复位信号
    input  wire [3:0]  a,
    input  wire [3:0]  b, 
    input  wire [3:0]  c,
    output wire [3:0]  y
);
    // 数据流重构为清晰的流水线结构
    // 第一级流水线：计算a和b的或逻辑
    reg  [3:0] a_reg, b_reg;    // 输入寄存器化
    reg  [3:0] stage1_result;   // 第一级计算结果
    wire [3:0] ab_or;           // a和b的或结果
    
    // 第二级流水线：计算最终输出
    reg  [3:0] c_reg;           // c信号寄存器化
    reg  [3:0] stage2_result;   // 最终计算结果
    
    // 输入寄存器化，减少扇入延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            c_reg <= 4'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
        end
    end
    
    // 第一级流水线计算
    assign ab_or = a_reg | b_reg;
    
    // 第一级流水线结果寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_result <= 4'b0;
        end else begin
            stage1_result <= ab_or;
        end
    end
    
    // 第二级流水线计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 4'b0;
        end else begin
            stage2_result <= stage1_result | c_reg;
        end
    end
    
    // 输出赋值
    assign y = stage2_result;
    
endmodule