//SystemVerilog
// 顶层比较器模块
module Comparator_RegSync #(parameter WIDTH = 4) (
    input               clk,      // 全局时钟
    input               rst_n,    // 低有效同步复位
    input  [WIDTH-1:0]  in1,      // 输入向量1
    input  [WIDTH-1:0]  in2,      // 输入向量2
    output              eq_out    // 寄存后的比较结果
);
    // 内部连线，用于连接比较模块和寄存器模块
    wire comparison_result;
    
    // 实例化组合逻辑比较器子模块
    Comparator_Core #(
        .WIDTH(WIDTH)
    ) comp_core_inst (
        .in1(in1),
        .in2(in2),
        .eq_out(comparison_result)
    );
    
    // 实例化同步寄存器子模块
    Register_Sync reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(comparison_result),
        .data_out(eq_out)
    );
    
endmodule

// 纯组合逻辑比较器子模块
module Comparator_Core #(parameter WIDTH = 4) (
    input  [WIDTH-1:0]  in1,      // 输入向量1
    input  [WIDTH-1:0]  in2,      // 输入向量2
    output              eq_out    // 比较结果
);
    // 使用连续赋值而非过程块，优化组合逻辑性能
    assign eq_out = (in1 == in2);
    
endmodule

// 通用同步寄存器子模块
module Register_Sync (
    input       clk,              // 时钟信号
    input       rst_n,            // 低有效同步复位
    input       data_in,          // 数据输入
    output reg  data_out          // 寄存数据输出
);
    // 复位逻辑处理
    always @(posedge clk) begin
        if (!rst_n) 
            data_out <= 1'b0;
    end
    
    // 数据寄存逻辑处理
    always @(posedge clk) begin
        if (rst_n)        
            data_out <= data_in;
    end
    
endmodule