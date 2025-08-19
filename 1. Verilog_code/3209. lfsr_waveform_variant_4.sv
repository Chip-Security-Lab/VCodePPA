//SystemVerilog
module lfsr_waveform(
    input i_clk,
    input i_rst,
    input i_valid,        // 替代原来的 i_enable，表示输入数据有效
    output o_ready,       // 新增输出信号，表示模块准备好接收数据
    output [7:0] o_random,
    output o_valid        // 新增输出信号，表示输出数据有效
);
    reg [15:0] lfsr;
    reg ready_reg;        // 内部 ready 状态寄存器
    reg valid_out_reg;    // 输出有效信号寄存器
    reg handshake_reg;    // 握手状态寄存器
    
    // 前移组合逻辑计算
    wire feedback = lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3];
    wire handshake = i_valid & ready_reg;  // 握手成功信号
    wire [15:0] next_lfsr = {lfsr[14:0], feedback};
    
    // 握手寄存（将握手信号寄存起来，减少输入端到第一级寄存器的路径延迟）
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst)
            handshake_reg <= 1'b0;
        else
            handshake_reg <= handshake;
    end
    
    // Ready 信号逻辑（重构以适应寄存器前移）
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst)
            ready_reg <= 1'b1;  // 复位后即可接收数据
        else if (handshake)
            ready_reg <= 1'b0;  // 握手成功后暂时不接收新数据
        else if (valid_out_reg)
            ready_reg <= 1'b1;  // 数据处理完成后可以接收新数据
    end
    
    // LFSR 逻辑（延迟一个周期，使用寄存的握手信号）
    always @(posedge i_clk) begin
        if (i_rst)
            lfsr <= 16'hACE1;
        else if (handshake_reg)
            lfsr <= next_lfsr;
    end
    
    // 输出有效信号逻辑（基于寄存的握手信号）
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst)
            valid_out_reg <= 1'b0;
        else
            valid_out_reg <= handshake_reg;  // 基于寄存的握手信号
    end
    
    // 输出赋值
    assign o_random = lfsr[7:0];
    assign o_ready = ready_reg;
    assign o_valid = valid_out_reg;
endmodule