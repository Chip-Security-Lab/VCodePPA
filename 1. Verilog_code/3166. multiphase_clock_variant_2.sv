//SystemVerilog
module multiphase_clock(
    input wire sys_clk,
    input wire rst,
    // Valid-Ready handshake interface
    input wire ready,
    output reg valid,
    output reg [7:0] phase_clks
);
    // 优化的移位寄存器实现
    reg [7:0] shift_reg;
    wire [7:0] next_shift_reg;
    
    // 简化逻辑，使用组合逻辑计算下一个状态
    assign next_shift_reg = {shift_reg[6:0], shift_reg[7]};
    
    // 简化握手逻辑，减少信号数量
    always @(posedge sys_clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 8'b00000001;
            valid <= 1'b0;
            phase_clks <= 8'b0;
        end else begin
            // 当处于有效状态且接收方准备好接收时更新输出和状态
            if (ready && (!valid || (valid && ready))) begin
                valid <= 1'b1;
                phase_clks <= shift_reg;
                shift_reg <= next_shift_reg;
            end else if (!ready && valid) begin
                // 保持当前状态，等待ready信号
                valid <= 1'b1;
            end else begin
                // 默认情况，准备下一个传输
                valid <= 1'b1;
            end
        end
    end
endmodule