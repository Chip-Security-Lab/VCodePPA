//SystemVerilog
module parking_counter(
    input wire clk,
    input wire reset,
    input wire car_entry,
    input wire car_exit,
    output reg [6:0] available_spaces,
    output reg lot_full
);
    // 状态编码优化为独热码，提高状态转换速度
    parameter [3:0] IDLE   = 4'b0001, 
                    ENTRY  = 4'b0010, 
                    EXIT   = 4'b0100, 
                    UPDATE = 4'b1000;
    parameter MAX_SPACES = 7'd100;
    
    reg [3:0] state, next_state;
    reg [6:0] next_available_spaces;
    reg next_lot_full;

    // 使用前寄存后计算模式，将FSM状态寄存器和输出寄存器分开
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            available_spaces <= MAX_SPACES;
            lot_full <= 1'b0;
        end else begin
            state <= next_state;
            available_spaces <= next_available_spaces;
            lot_full <= next_lot_full;
        end
    end
    
    // 将组合逻辑拆分为两个并行处理块，减少关键路径
    always @(*) begin
        // 默认保持当前值，减少无效切换
        next_available_spaces = available_spaces;
        
        // 状态相关的计数逻辑
        case (1'b1) // 独热码状态判断
            state[1]: begin // ENTRY
                if (available_spaces > 0)
                    next_available_spaces = available_spaces - 1'b1;
            end
            state[2]: begin // EXIT
                if (available_spaces < MAX_SPACES)
                    next_available_spaces = available_spaces + 1'b1;
            end
            default: next_available_spaces = available_spaces;
        endcase
        
        // 并行计算lot_full信号，不依赖状态机
        next_lot_full = (next_available_spaces == 0);
    end
    
    // 状态转换逻辑优化
    always @(*) begin
        // 默认保持当前状态
        next_state = state;
        
        // 使用case优化条件分支结构
        case (1'b1) // 独热码状态判断
            state[0]: begin // IDLE
                if (car_entry)
                    next_state = ENTRY;
                else if (car_exit)
                    next_state = EXIT;
            end
            state[1], state[2]: begin // ENTRY, EXIT
                next_state = UPDATE;
            end
            state[3]: begin // UPDATE
                // 并行判断，减少逻辑链
                if (car_entry && !car_exit)
                    next_state = ENTRY;
                else if (!car_entry && car_exit)
                    next_state = EXIT;
                else
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule