//SystemVerilog
module async_comb_reg(
    input [7:0] parallel_data,
    input load_signal,
    output [7:0] reg_output
);
    // 直接使用组合逻辑实现寄存器功能，消除中间寄存器
    reg [7:0] stored_value;

    // 使用非阻塞赋值以避免竞争冒险
    always @(load_signal or parallel_data)
        if (load_signal) stored_value <= parallel_data;
    
    // 直接连接输出
    assign reg_output = stored_value;
endmodule