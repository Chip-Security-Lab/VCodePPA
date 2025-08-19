//SystemVerilog
module pulse_recovery_unit (
    input wire clk,
    input wire rst_n,
    input wire noisy_pulse,
    output reg clean_pulse,
    output reg pulse_detected
);
    // State definitions with registered versions for fan-out reduction
    localparam IDLE = 2'b00;
    localparam PULSE_START = 2'b01;
    localparam PULSE_ACTIVE = 2'b10;
    localparam RECOVERY = 2'b11;
    
    reg [1:0] state, next_state;
    reg [1:0] next_state_buf1, next_state_buf2; // 扇出缓冲寄存器
    reg [3:0] count;
    reg [3:0] count_buf1, count_buf2; // 扇出缓冲寄存器
    
    // 为高扇出状态常量添加缓冲寄存器
    reg [1:0] IDLE_buf1, IDLE_buf2;
    
    // 状态缓冲器初始化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            IDLE_buf1 <= IDLE;
            IDLE_buf2 <= IDLE;
            next_state_buf1 <= IDLE;
            next_state_buf2 <= IDLE;
            count_buf1 <= 4'd0;
            count_buf2 <= 4'd0;
        end else begin
            IDLE_buf1 <= IDLE;
            IDLE_buf2 <= IDLE;
            next_state_buf1 <= next_state;
            next_state_buf2 <= next_state;
            count_buf1 <= count;
            count_buf2 <= count;
        end
    end
    
    // State machine with reduced fan-out
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= next_state_buf1; // 使用缓冲的next_state
    end
    
    // Next state logic - 使用扇出均衡
    always @(*) begin
        case (state)
            IDLE_buf1: next_state = noisy_pulse ? PULSE_START : IDLE_buf1;
            PULSE_START: next_state = PULSE_ACTIVE;
            PULSE_ACTIVE: next_state = (count_buf1 >= 4'd8) ? RECOVERY : PULSE_ACTIVE;
            RECOVERY: next_state = (count_buf2 >= 4'd4) ? IDLE_buf2 : RECOVERY;
            default: next_state = IDLE_buf2;
        endcase
    end
    
    // Output and counter logic - 使用缓冲信号降低扇出负载
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 4'd0;
            clean_pulse <= 1'b0;
            pulse_detected <= 1'b0;
        end else begin
            case (next_state_buf2) // 使用缓冲的next_state
                IDLE_buf1: begin
                    count <= 4'd0;
                    clean_pulse <= 1'b0;
                    pulse_detected <= 1'b0;
                end
                PULSE_START: begin
                    count <= 4'd0;
                    clean_pulse <= 1'b1;
                    pulse_detected <= 1'b1;
                end
                PULSE_ACTIVE: begin
                    count <= count + 1'b1;
                    clean_pulse <= 1'b1;
                end
                RECOVERY: begin
                    count <= count + 1'b1;
                    clean_pulse <= 1'b0;
                    pulse_detected <= 1'b0;
                end
            endcase
        end
    end
endmodule