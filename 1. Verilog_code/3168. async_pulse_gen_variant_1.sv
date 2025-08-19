//SystemVerilog
module async_pulse_gen(
    input data_in,
    input reset,
    output pulse_out
);
    reg data_delayed;
    
    // 使用阻塞赋值优化逻辑路径
    always @(*) begin
        if (reset)
            data_delayed = 1'b0;
        else
            data_delayed = data_in;
    end
    
    // 通过直接检测边沿逻辑改进脉冲生成
    assign pulse_out = data_in & (~data_delayed);
endmodule