//SystemVerilog
module boot_sequence_reset(
    input  wire       clk,
    input  wire       power_good,
    output reg  [3:0] rst_seq,
    output reg        boot_complete
);
    // 使用独热编码替代二进制计数，减少状态转换解码的组合逻辑深度
    reg [4:0] boot_state;
    localparam STATE_RESET = 5'b00001;
    localparam STATE_BOOT1 = 5'b00010;
    localparam STATE_BOOT2 = 5'b00100;
    localparam STATE_BOOT3 = 5'b01000;
    localparam STATE_DONE  = 5'b10000;
    
    // 预解码状态输出，减少组合逻辑延迟
    reg [3:0] next_rst_seq;
    reg       next_boot_complete;
    reg [4:0] next_state;
    
    // 状态转移和输出逻辑
    always @(*) begin
        // 默认保持当前状态和输出
        next_state = boot_state;
        next_rst_seq = rst_seq;
        next_boot_complete = boot_complete;
        
        case (1'b1) // 独热编码优化的case语句
            boot_state[0]: begin // STATE_RESET
                next_state = STATE_BOOT1;
                next_rst_seq = 4'b0111;
                next_boot_complete = 1'b0;
            end
            boot_state[1]: begin // STATE_BOOT1
                next_state = STATE_BOOT2;
                next_rst_seq = 4'b0011;
                next_boot_complete = 1'b0;
            end
            boot_state[2]: begin // STATE_BOOT2
                next_state = STATE_BOOT3;
                next_rst_seq = 4'b0001;
                next_boot_complete = 1'b0;
            end
            boot_state[3]: begin // STATE_BOOT3
                next_state = STATE_DONE;
                next_rst_seq = 4'b0000;
                next_boot_complete = 1'b1;
            end
            boot_state[4]: begin // STATE_DONE
                // 保持当前状态和输出
            end
            default: begin
                next_state = STATE_RESET;
                next_rst_seq = 4'b1111;
                next_boot_complete = 1'b0;
            end
        endcase
    end
    
    // 状态寄存器和输出寄存器更新
    always @(posedge clk or negedge power_good) begin
        if (!power_good) begin
            boot_state <= STATE_RESET;
            rst_seq <= 4'b1111;
            boot_complete <= 1'b0;
        end else begin
            boot_state <= next_state;
            rst_seq <= next_rst_seq;
            boot_complete <= next_boot_complete;
        end
    end
endmodule