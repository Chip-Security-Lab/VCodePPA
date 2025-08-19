//SystemVerilog
module piso_shifter (
    input wire clk, clear, load,
    input wire [7:0] parallel_data,
    output wire serial_out
);
    // 内部寄存器信号
    reg [7:0] shift_reg;
    reg [7:0] pipeline_reg;
    
    // 控制信号寄存器用于延迟一个周期
    reg clear_pipe, load_pipe;
    
    // 第一阶段：处理控制信号和准备数据
    always @(posedge clk) begin
        // 缓存控制信号
        clear_pipe <= clear;
        load_pipe <= load;
        
        // 缓存输入数据和部分计算结果
        pipeline_reg <= parallel_data;
    end
    
    // 第二阶段：完成状态更新
    always @(posedge clk) begin
        if (clear_pipe)
            shift_reg <= 8'h00;
        else if (load_pipe)
            shift_reg <= pipeline_reg;
        else
            shift_reg <= {shift_reg[6:0], 1'b0};
    end
    
    // 输出赋值
    assign serial_out = shift_reg[7];
endmodule