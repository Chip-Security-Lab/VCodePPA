//SystemVerilog
module fsm_parity_check (
    input clk, rst_n,
    input data_valid,
    input [7:0] data,
    output reg parity
);
    // 状态编码优化为独热码，提高可靠性和可合成性
    parameter [1:0] IDLE = 2'b01;
    parameter [1:0] CALC = 2'b10;
    
    reg [1:0] state;
    reg [1:0] next_state;
    
    // 状态转移逻辑与输出逻辑分离
    always @(*) begin
        next_state = IDLE; // 默认值
        case(state)
            IDLE: next_state = data_valid ? CALC : IDLE;
            CALC: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            parity <= 1'b0;
        end else begin
            state <= next_state;
            if (state == IDLE && data_valid) begin
                // 使用简化的奇偶校验计算
                parity <= data[0] ^ data[1] ^ data[2] ^ data[3] ^ 
                          data[4] ^ data[5] ^ data[6] ^ data[7];
            end
        end
    end
endmodule