module sync_low_rst_fsm(
    input wire clk,
    input wire rst_n,
    input wire trigger,
    output reg state_out
);
    // 替换SystemVerilog枚举类型为参数
    localparam IDLE = 1'b0;
    localparam ACTIVE = 1'b1;
    
    reg state, next_state;

    always @(posedge clk) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        case(state)
            IDLE:   next_state = trigger ? ACTIVE : IDLE;
            ACTIVE: next_state = trigger ? ACTIVE : IDLE;
            default: next_state = IDLE;
        endcase
        state_out = (state == ACTIVE);
    end
endmodule