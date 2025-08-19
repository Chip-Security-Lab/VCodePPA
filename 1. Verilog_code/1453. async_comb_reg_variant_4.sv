//SystemVerilog
module async_comb_reg(
    input [7:0] parallel_data,
    input load_signal,
    output [7:0] reg_output
);
    // 存储寄存器值
    reg [7:0] stored_value;
    
    // 处理数据加载逻辑
    always @(load_signal) begin
        if (load_signal) begin
            stored_value <= parallel_data;
        end
    end
    
    // 处理并行数据变化时的更新
    always @(parallel_data) begin
        if (load_signal) begin
            stored_value <= parallel_data;
        end
    end
    
    // 输出赋值
    assign reg_output = stored_value;
    
endmodule