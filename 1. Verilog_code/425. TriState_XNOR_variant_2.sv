//SystemVerilog
module TriState_XNOR (
    input        clk,      // 时钟输入
    input        rst_n,    // 复位信号
    input        oe,       // 输出使能信号
    input  [3:0] in1,      // 第一个输入数据
    input  [3:0] in2,      // 第二个输入数据
    output [3:0] res       // 结果输出
);
    // 将XNOR操作分解为更小的部分，以平衡关键路径
    reg [3:0] xnor_result_stage1;
    reg       oe_stage1;
    
    // 中间信号，用于拆分组合逻辑路径
    reg [3:0] in1_reg, in2_reg;
    reg [3:0] xor_temp;
    
    // 注册输入信号以减少输入路径延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in1_reg <= 4'b0000;
            in2_reg <= 4'b0000;
        end else begin
            in1_reg <= in1;
            in2_reg <= in2;
        end
    end
    
    // 第一级流水线: 计算XOR并提前缓存OE
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_temp  <= 4'b0000;
            oe_stage1 <= 1'b0;
        end else begin
            xor_temp  <= in1_reg ^ in2_reg;
            oe_stage1 <= oe;
        end
    end
    
    // 第二级流水线: 完成XNOR计算(取反操作)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_result_stage1 <= 4'b0000;
        end else begin
            xnor_result_stage1 <= ~xor_temp;
        end
    end
    
    // 三态输出控制逻辑 - 直接分配到输出，不需要额外的寄存器
    assign res = oe_stage1 ? xnor_result_stage1 : 4'bzzzz;
    
endmodule