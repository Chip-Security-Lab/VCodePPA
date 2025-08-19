//SystemVerilog
module or_gate_8input_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [7:0] c,
    input  wire [7:0] d,
    input  wire [7:0] e,
    input  wire [7:0] f,
    input  wire [7:0] g,
    input  wire [7:0] h,
    output wire [7:0] y
);
    // 使用并行前缀树结构实现更平衡的OR网络
    // 第一级 - 4对并行OR运算
    wire [7:0] ab, cd, ef, gh;
    
    assign ab = a | b;
    assign cd = c | d;
    assign ef = e | f;
    assign gh = g | h;
    
    // 第二级 - 2对并行OR运算
    wire [7:0] abcd, efgh;
    
    assign abcd = ab | cd;
    assign efgh = ef | gh;
    
    // 输出级 - 最终OR运算
    assign y = abcd | efgh;
    
endmodule