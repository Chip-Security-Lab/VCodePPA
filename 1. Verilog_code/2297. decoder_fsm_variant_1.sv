//SystemVerilog
module decoder_fsm (
    input clk, rst_n,
    input [3:0] addr,
    output reg [7:0] decoded
);
    // 使用参数替代enum类型
    parameter IDLE = 2'b00, DECODE = 2'b01, HOLD = 2'b10;
    
    reg [1:0] curr_state, next_state;
    reg [7:0] next_decoded;
    
    // 状态寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_state <= IDLE;
        end else begin
            curr_state <= next_state;
        end
    end
    
    // 输出寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded <= 8'h00;
        end else begin
            decoded <= next_decoded;
        end
    end
    
    // 组合逻辑：状态转换
    always @(*) begin
        case(curr_state)
            IDLE:    next_state = (addr != 0) ? DECODE : IDLE;
            DECODE:  next_state = HOLD;
            HOLD:    next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 组合逻辑：输出解码
    always @(*) begin
        next_decoded = decoded; // 默认保持当前值
        
        if (curr_state == DECODE) begin
            if (addr < 8) 
                next_decoded = (8'h01 << addr);
            else
                next_decoded = 8'h00;
        end
    end
endmodule