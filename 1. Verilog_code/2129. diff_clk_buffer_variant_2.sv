//SystemVerilog

///////////////////////////////////////////////////////////////////////////////
// 顶层模块：差分时钟缓冲器
///////////////////////////////////////////////////////////////////////////////
module diff_clk_buffer #(
    parameter INVERT_N = 1  // 参数化设计：是否反转N信号，默认为1（反转）
) (
    input  wire single_ended_clk,  // 单端时钟输入
    output wire clk_p,             // 差分时钟正极输出
    output wire clk_n              // 差分时钟负极输出
);
    
    // 实例化正极信号生成模块
    clk_p_generator p_gen (
        .clk_in(single_ended_clk),
        .clk_out(clk_p)
    );
    
    // 实例化负极信号生成模块
    clk_n_generator #(
        .INVERT(INVERT_N)
    ) n_gen (
        .clk_in(single_ended_clk),
        .clk_out(clk_n)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// 子模块：正极时钟信号生成器
///////////////////////////////////////////////////////////////////////////////
module clk_p_generator (
    input  wire clk_in,   // 输入时钟
    output wire clk_out   // 输出时钟（正极）
);
    
    // 正极信号可以直接透传或进行缓冲
    // 使用非阻塞赋值以便于后续可能的时序控制
    assign clk_out = clk_in;
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// 子模块：负极时钟信号生成器
///////////////////////////////////////////////////////////////////////////////
module clk_n_generator #(
    parameter INVERT = 1  // 参数化，控制是否反转信号
) (
    input  wire clk_in,   // 输入时钟
    output wire clk_out   // 输出时钟（负极）
);
    
    // 使用条件运算符替代generate-if结构，简化逻辑
    assign clk_out = INVERT ? ~clk_in : clk_in;
    
endmodule