//SystemVerilog
module sync_low_rst_fsm(
    input wire clk,
    input wire rst_n,
    input wire trigger,
    output reg state_out
);
    // 定义状态编码参数
    localparam IDLE = 1'b0;
    localparam ACTIVE = 1'b1;
    
    // 当前状态寄存器
    reg state;
    
    // 将trigger信号寄存后再使用，实现前向寄存器重定时
    reg trigger_reg;
    
    // 捕获trigger信号
    always @(posedge clk) begin
        if (!rst_n)
            trigger_reg <= 1'b0;
        else
            trigger_reg <= trigger;
    end
    
    // 状态转移逻辑 - 使用重定时后的trigger_reg信号
    always @(posedge clk) begin
        if (!rst_n)
            state <= IDLE;
        else begin
            case(state)
                IDLE:   state <= trigger_reg ? ACTIVE : IDLE;
                ACTIVE: state <= trigger_reg ? ACTIVE : IDLE;
                default: state <= IDLE;
            endcase
        end
    end
    
    // 输出逻辑
    always @(posedge clk) begin
        if (!rst_n)
            state_out <= 1'b0;
        else
            state_out <= (state == ACTIVE);
    end
endmodule