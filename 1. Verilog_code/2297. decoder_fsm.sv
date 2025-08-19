module decoder_fsm (
    input clk, rst_n,
    input [3:0] addr,
    output reg [7:0] decoded
);
    // 使用参数替代enum类型
    parameter IDLE = 2'b00, DECODE = 2'b01, HOLD = 2'b10;
    
    reg [1:0] curr_state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_state <= IDLE;
            decoded <= 8'h00;
        end else begin
            case(curr_state)
                IDLE: if (addr != 0) curr_state <= DECODE;
                DECODE: begin
                    // 确保地址在有效范围内
                    if (addr < 8) 
                        decoded <= (8'h01 << addr);
                    else
                        decoded <= 8'h00;
                    curr_state <= HOLD;
                end
                HOLD: curr_state <= IDLE;
                default: curr_state <= IDLE;
            endcase
        end
    end
endmodule