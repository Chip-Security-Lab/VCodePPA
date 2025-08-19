//SystemVerilog
module dram_ctrl_param #(
    parameter tRCD = 3,
    parameter tRP = 2,
    parameter tRAS = 5
)(
    input clk,
    input reset,
    input refresh_req,
    output reg refresh_ack
);

    localparam IDLE = 2'd0,
               REFRESH_DELAY = 2'd1,
               REFRESH_ACTIVE = 2'd2;
    
    reg [1:0] refresh_state;
    reg [1:0] refresh_state_next;
    reg [7:0] refresh_counter;
    reg [7:0] refresh_counter_next;
    reg refresh_ack_next;
    
    // 组合逻辑提前计算
    wire counter_zero = (refresh_counter == 0);
    wire refresh_delay_done = (refresh_state == REFRESH_DELAY) && counter_zero;
    wire refresh_active_done = (refresh_state == REFRESH_ACTIVE) && counter_zero;
    
    // 状态机下一状态逻辑
    always @(*) begin
        case(refresh_state)
            IDLE: begin
                refresh_state_next = refresh_req ? REFRESH_DELAY : IDLE;
                refresh_counter_next = refresh_req ? tRCD : refresh_counter;
                refresh_ack_next = 0;
            end
            REFRESH_DELAY: begin
                refresh_state_next = refresh_delay_done ? REFRESH_ACTIVE : REFRESH_DELAY;
                refresh_counter_next = refresh_delay_done ? tRAS : (refresh_counter - 1);
                refresh_ack_next = 0;
            end
            REFRESH_ACTIVE: begin
                refresh_state_next = refresh_active_done ? IDLE : REFRESH_ACTIVE;
                refresh_counter_next = refresh_active_done ? 0 : (refresh_counter - 1);
                refresh_ack_next = refresh_active_done;
            end
            default: begin
                refresh_state_next = IDLE;
                refresh_counter_next = 0;
                refresh_ack_next = 0;
            end
        endcase
    end
    
    // 时序逻辑
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            refresh_state <= IDLE;
            refresh_counter <= 0;
            refresh_ack <= 0;
        end else begin
            refresh_state <= refresh_state_next;
            refresh_counter <= refresh_counter_next;
            refresh_ack <= refresh_ack_next;
        end
    end
endmodule