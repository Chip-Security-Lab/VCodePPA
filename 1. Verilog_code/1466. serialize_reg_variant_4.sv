//SystemVerilog
module serialize_reg(
    input clk, reset,
    input [7:0] parallel_in,
    input load, shift_out,
    output reg [7:0] p_out,
    output serial_out
);
    // 内部缓冲信号
    reg load_buf1, load_buf2;
    reg shift_out_buf1, shift_out_buf2;
    reg [7:0] parallel_in_buf;
    reg serial_out_reg;
    
    // 第一级缓冲寄存器 - 降低扇出负载
    always @(posedge clk) begin
        load_buf1 <= load;
        shift_out_buf1 <= shift_out;
    end
    
    // 第二级缓冲寄存器 - 进一步降低时序关键路径延迟
    always @(posedge clk) begin
        load_buf2 <= load_buf1;
        shift_out_buf2 <= shift_out_buf1;
    end
    
    // 数据输入缓冲 - 保证数据稳定性
    always @(posedge clk) begin
        parallel_in_buf <= parallel_in;
    end
    
    // 主数据寄存器 - 重置和加载逻辑
    always @(posedge clk) begin
        if (reset)
            p_out <= 8'b0;
        else if (load_buf2)
            p_out <= parallel_in_buf;
        else if (shift_out_buf2)
            p_out <= {p_out[6:0], 1'b0};
    end
    
    // 串行输出寄存器 - 隔离输出负载
    always @(posedge clk) begin
        serial_out_reg <= p_out[7];
    end
    
    // 连续赋值输出
    assign serial_out = serial_out_reg;
endmodule