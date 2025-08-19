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
    reg [7:0] refresh_counter;
    reg [7:0] counter_inv;
    wire counter_zero;
    wire [1:0] next_state;
    
    // 优化计数器逻辑 - 使用位操作
    assign counter_zero = ~|refresh_counter;
    
    // 优化状态转换逻辑 - 使用查找表方式
    assign next_state = refresh_state == IDLE ? (refresh_req ? REFRESH_DELAY : IDLE) :
                       refresh_state == REFRESH_DELAY ? (counter_zero ? REFRESH_ACTIVE : REFRESH_DELAY) :
                       refresh_state == REFRESH_ACTIVE ? (counter_zero ? IDLE : REFRESH_ACTIVE) :
                       IDLE;
    
    // 条件反相减法器实现
    always @(*) begin
        if (refresh_state == REFRESH_DELAY || refresh_state == REFRESH_ACTIVE) begin
            counter_inv = ~refresh_counter;
        end else begin
            counter_inv = refresh_counter;
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            refresh_state <= IDLE;
            refresh_ack <= 0;
            refresh_counter <= 0;
        end else begin
            refresh_state <= next_state;
            
            case(refresh_state)
                IDLE: begin
                    refresh_ack <= 0;
                    refresh_counter <= refresh_req ? tRCD : 0;
                end
                REFRESH_DELAY: begin
                    refresh_counter <= counter_zero ? tRAS : counter_inv + 1'b1;
                end
                REFRESH_ACTIVE: begin
                    refresh_ack <= counter_zero;
                    refresh_counter <= counter_zero ? 0 : counter_inv + 1'b1;
                end
                default: begin
                    refresh_state <= IDLE;
                    refresh_ack <= 0;
                    refresh_counter <= 0;
                end
            endcase
        end
    end
endmodule