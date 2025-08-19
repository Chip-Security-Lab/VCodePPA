//SystemVerilog
module boot_sequence_reset(
    input  wire       clk,
    input  wire       power_good,
    output reg  [3:0] rst_seq,
    output reg        boot_complete
);
    // 使用单热码编码来减少状态转换时的切换活动
    localparam RESET_STATE = 5'b00001;
    localparam STAGE1      = 5'b00010;
    localparam STAGE2      = 5'b00100;
    localparam STAGE3      = 5'b01000;
    localparam COMPLETE    = 5'b10000;
    
    reg [4:0] current_state, next_state;
    
    // 状态寄存器
    always @(posedge clk or negedge power_good) begin
        if (!power_good) begin
            current_state <= RESET_STATE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // 下一状态逻辑 - 组合逻辑
    always @(*) begin
        case (1'b1) // 使用单热码的并行比较
            current_state[0]: next_state = STAGE1;
            current_state[1]: next_state = STAGE2;
            current_state[2]: next_state = STAGE3;
            current_state[3]: next_state = COMPLETE;
            current_state[4]: next_state = COMPLETE;
            default:          next_state = RESET_STATE;
        endcase
    end
    
    // 输出逻辑 - 优化为并行查找
    always @(posedge clk or negedge power_good) begin
        if (!power_good) begin
            rst_seq       <= 4'b1111;
            boot_complete <= 1'b0;
        end else begin
            // 单热码并行比较来确定输出
            case (1'b1)
                next_state[0]: begin rst_seq <= 4'b1111; boot_complete <= 1'b0; end
                next_state[1]: begin rst_seq <= 4'b0111; boot_complete <= 1'b0; end
                next_state[2]: begin rst_seq <= 4'b0011; boot_complete <= 1'b0; end
                next_state[3]: begin rst_seq <= 4'b0001; boot_complete <= 1'b0; end
                next_state[4]: begin rst_seq <= 4'b0000; boot_complete <= 1'b1; end
                default:       begin rst_seq <= 4'b1111; boot_complete <= 1'b0; end
            endcase
        end
    end
endmodule