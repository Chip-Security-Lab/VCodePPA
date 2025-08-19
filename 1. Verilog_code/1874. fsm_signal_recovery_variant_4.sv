//SystemVerilog
module fsm_signal_recovery (
    input wire clk, rst_n,
    input wire signal_detect,
    input wire [3:0] signal_value,
    output reg [3:0] recovered_value,
    output reg lock_status
);
    // 优化状态编码，使用单热编码降低状态转换逻辑复杂度
    localparam IDLE   = 4'b0001, 
               DETECT = 4'b0010, 
               LOCK   = 4'b0100, 
               TRACK  = 4'b1000;
               
    reg [3:0] state, next_state;
    reg [2:0] counter; // 优化位宽，原计数器最大值为8，仅需3位
    
    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            state <= IDLE;
        else 
            state <= next_state;
    end
    
    // 下一状态逻辑优化
    always @(*) begin
        // 默认保持当前状态
        next_state = state;
        
        case (1'b1) // 单热码优化case语句
            state[0]: // IDLE
                if (signal_detect) next_state = DETECT;
            
            state[1]: // DETECT
                if (counter[2] == 1'b1) next_state = LOCK; // 直接测试MSB位，等效于>=8
            
            state[2], // LOCK
            state[3]: // TRACK
                if (!signal_detect) next_state = IDLE;
                
            default: next_state = IDLE;
        endcase
    end
    
    // 输出逻辑和计数器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 3'd0;
            recovered_value <= 4'd0;
            lock_status <= 1'b0;
        end 
        else begin
            // 默认保持当前值
            
            case (1'b1) // 单热码优化case语句
                state[0]: begin // IDLE
                    counter <= 3'd0;
                    lock_status <= 1'b0;
                end
                
                state[1]: begin // DETECT
                    if (counter != 3'b111) // 防止溢出
                        counter <= counter + 1'b1;
                end
                
                state[2]: begin // LOCK
                    recovered_value <= signal_value;
                    lock_status <= 1'b1;
                end
                
                state[3]: begin // TRACK
                    recovered_value <= signal_value;
                end
            endcase
        end
    end
endmodule