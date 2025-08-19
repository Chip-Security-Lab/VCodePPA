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
    // 使用localparam定义状态
    localparam IDLE = 2'd0,
               REFRESH_DELAY = 2'd1,
               REFRESH_ACTIVE = 2'd2;
    
    reg [1:0] refresh_state;
    reg [7:0] refresh_counter;
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            refresh_state <= IDLE;
            refresh_ack <= 0;
            refresh_counter <= 0;
        end else begin
            case(refresh_state)
                IDLE: begin
                    if(refresh_req) begin
                        refresh_state <= REFRESH_DELAY;
                        refresh_counter <= tRCD;
                    end
                    refresh_ack <= 0;
                end
                REFRESH_DELAY: begin
                    if(refresh_counter == 0) begin
                        refresh_state <= REFRESH_ACTIVE;
                        refresh_counter <= tRAS;
                    end else 
                        refresh_counter <= refresh_counter - 1;
                end
                REFRESH_ACTIVE: begin
                    if(refresh_counter == 0) begin
                        refresh_state <= IDLE;
                        refresh_ack <= 1;
                    end else 
                        refresh_counter <= refresh_counter - 1;
                end
                default: refresh_state <= IDLE;  // 添加默认状态
            endcase
        end
    end
endmodule
