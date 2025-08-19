//SystemVerilog
module sleep_mode_clock_gate (
    input  wire sys_clk,
    input  wire sleep_req,
    input  wire wake_event,
    input  wire rst_n,
    output wire core_clk
);
    // 将组合逻辑移到寄存器前
    wire [1:0] sleep_ctrl;
    assign sleep_ctrl = {wake_event, sleep_req};
    
    // 状态预译码逻辑
    wire next_sleep_state;
    wire maintain_state;
    wire wake_up;
    wire go_sleep;
    
    assign wake_up = (sleep_ctrl == 2'b10) || (sleep_ctrl == 2'b11);
    assign go_sleep = (sleep_ctrl == 2'b01);
    assign maintain_state = (sleep_ctrl == 2'b00);
    
    reg sleep_state;
    
    // 前向重定时：将寄存器移到组合逻辑之后
    assign next_sleep_state = wake_up ? 1'b0 :
                             go_sleep ? 1'b1 :
                             maintain_state ? sleep_state : sleep_state;
    
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n)
            sleep_state <= 1'b0;
        else
            sleep_state <= next_sleep_state;
    end
    
    assign core_clk = sys_clk & ~sleep_state;
endmodule