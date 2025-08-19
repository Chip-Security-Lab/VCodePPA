//SystemVerilog
module midi_encoder (
    input wire clk, 
    input wire note_on,
    input wire [6:0] note, 
    input wire [6:0] velocity,
    output reg [7:0] tx_byte
);
    // 定义状态编码 - 使用独热编码提高稳定性和可靠性
    localparam [2:0] IDLE = 3'b001;
    localparam [2:0] NOTE = 3'b010;
    localparam [2:0] VEL  = 3'b100;
    
    reg [2:0] state, next_state;
    
    // 状态转移逻辑 - 分离组合逻辑和时序逻辑以优化时序性能
    always @(*) begin
        next_state = state;
        case(state)
            IDLE: begin
                if(note_on)
                    next_state = NOTE;
            end
            NOTE: next_state = VEL;
            VEL:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 状态寄存器更新
    always @(posedge clk) begin
        state <= next_state;
    end
    
    // 输出逻辑
    always @(posedge clk) begin
        case(state)
            IDLE: begin
                if(note_on)
                    tx_byte <= 8'h90;
            end
            NOTE: tx_byte <= {1'b0, note};
            VEL:  tx_byte <= {1'b0, velocity};
            default: tx_byte <= tx_byte; // 保持当前值
        endcase
    end
endmodule