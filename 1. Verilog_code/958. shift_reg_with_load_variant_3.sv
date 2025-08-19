//SystemVerilog
module shift_reg_with_load (
    input wire clk, reset,
    input wire shift_en, load_en,
    input wire serial_in,
    input wire [7:0] parallel_in,
    output wire serial_out,
    output wire [7:0] parallel_out
);
    // 第一级流水线 - 计算控制逻辑和中间结果
    reg load_en_pipe, shift_en_pipe;
    reg [7:0] parallel_in_pipe;
    reg serial_in_pipe;
    reg [7:0] shift_reg;
    reg [7:0] shift_reg_next;
    reg [7:0] shift_partial;
    
    // 第一级流水线寄存器 - 缓存输入信号
    always @(posedge clk) begin
        if (reset) begin
            load_en_pipe <= 1'b0;
            shift_en_pipe <= 1'b0;
            parallel_in_pipe <= 8'h00;
            serial_in_pipe <= 1'b0;
        end else begin
            load_en_pipe <= load_en;
            shift_en_pipe <= shift_en;
            parallel_in_pipe <= parallel_in;
            serial_in_pipe <= serial_in;
        end
    end
    
    // 预计算下一个状态的部分逻辑
    always @(*) begin
        if (shift_en_pipe)
            shift_partial = {shift_reg[6:0], serial_in_pipe};
        else
            shift_partial = shift_reg;
    end
    
    // 第二级组合逻辑 - 最终决定下一个状态
    always @(*) begin
        if (reset)
            shift_reg_next = 8'h00;
        else if (load_en_pipe)
            shift_reg_next = parallel_in_pipe;
        else
            shift_reg_next = shift_partial;
    end
    
    // 最终寄存器阶段
    always @(posedge clk) begin
        shift_reg <= shift_reg_next;
    end
    
    assign serial_out = shift_reg[7];
    assign parallel_out = shift_reg;
endmodule