//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 Verilog标准
// 顶层模块
module differential_recovery (
    input wire clk,
    input wire [7:0] pos_signal,
    input wire [7:0] neg_signal,
    output wire [8:0] recovered_signal
);
    // 内部连线
    wire comparison_result;
    wire [7:0] subtraction_result;
    
    // 为高扇出信号添加缓冲寄存器
    reg [7:0] pos_signal_buf1, pos_signal_buf2;
    reg [7:0] neg_signal_buf1, neg_signal_buf2;
    wire is_neg;
    reg is_neg_buf1, is_neg_buf2;
    reg [7:0] subtraction_result_buf;
    
    // 在时钟边沿更新缓冲寄存器
    always @(posedge clk) begin
        // 为pos_signal和neg_signal创建两组缓冲寄存器用于不同模块
        pos_signal_buf1 <= pos_signal;
        pos_signal_buf2 <= pos_signal;
        neg_signal_buf1 <= neg_signal;
        neg_signal_buf2 <= neg_signal;
        
        // 为is_neg信号创建缓冲寄存器
        is_neg_buf1 <= is_neg;
        is_neg_buf2 <= is_neg;
        
        // 为subtraction_result创建缓冲寄存器
        subtraction_result_buf <= subtraction_result;
    end
    
    // 实例化子模块，使用缓冲信号
    signal_comparator comparator_inst (
        .pos_signal(pos_signal_buf1),
        .neg_signal(neg_signal_buf1),
        .is_neg(is_neg)
    );
    
    signal_subtractor subtractor_inst (
        .pos_signal(pos_signal_buf2),
        .neg_signal(neg_signal_buf2),
        .is_neg(is_neg_buf1),
        .subtraction_result(subtraction_result)
    );
    
    signal_combiner combiner_inst (
        .clk(clk),
        .is_neg(is_neg_buf2),
        .subtraction_result(subtraction_result_buf),
        .recovered_signal(recovered_signal)
    );
    
endmodule

// 子模块1: 比较器模块 - 判断信号大小关系
module signal_comparator (
    input wire [7:0] pos_signal,
    input wire [7:0] neg_signal,
    output wire is_neg
);
    // 如果负信号大于正信号，输出1，否则输出0
    assign is_neg = (neg_signal > pos_signal);
    
endmodule

// 子模块2: 减法器模块 - 计算两个信号的绝对差值
module signal_subtractor (
    input wire [7:0] pos_signal,
    input wire [7:0] neg_signal,
    input wire is_neg,
    output wire [7:0] subtraction_result
);
    // 根据比较结果选择适当的减法操作
    assign subtraction_result = is_neg ? (neg_signal - pos_signal) : (pos_signal - neg_signal);
    
endmodule

// 子模块3: 合并器模块 - 组合符号位和差值，并进行时序处理
module signal_combiner (
    input wire clk,
    input wire is_neg,
    input wire [7:0] subtraction_result,
    output reg [8:0] recovered_signal
);
    // 同步组合符号位和差值
    always @(posedge clk) begin
        recovered_signal <= {is_neg, subtraction_result};
    end
    
endmodule