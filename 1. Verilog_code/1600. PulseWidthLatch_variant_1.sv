//SystemVerilog
module PulseWidthLatch (
    input clk,
    input rst_n,
    input pulse,
    input ack,
    output reg req,
    output reg [15:0] width_count
);

// 状态定义
typedef enum logic [1:0] {
    IDLE,
    COUNTING,
    DATA_READY
} state_t;

// 内部信号
reg [15:0] count_buffer;
reg last_pulse;
state_t current_state;
state_t next_state;

// 状态寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
        last_pulse <= 1'b0;
        count_buffer <= 16'd0;
        req <= 1'b0;
        width_count <= 16'd0;
    end else begin
        current_state <= next_state;
        last_pulse <= pulse;
    end
end

// 状态转换逻辑
always @(*) begin
    case (current_state)
        IDLE: begin
            if (pulse && !last_pulse) begin
                next_state = COUNTING;
            end else begin
                next_state = IDLE;
            end
        end
        COUNTING: begin
            if (!pulse) begin
                next_state = DATA_READY;
            end else begin
                next_state = COUNTING;
            end
        end
        DATA_READY: begin
            if (req && ack) begin
                next_state = IDLE;
            end else begin
                next_state = DATA_READY;
            end
        end
        default: next_state = IDLE;
    endcase
end

// 计数逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_buffer <= 16'd0;
    end else if (current_state == COUNTING) begin
        count_buffer <= count_buffer + 1'b1;
    end else if (current_state == IDLE) begin
        count_buffer <= 16'd0;
    end
end

// 输出控制逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        req <= 1'b0;
        width_count <= 16'd0;
    end else begin
        case (current_state)
            DATA_READY: begin
                if (!req) begin
                    req <= 1'b1;
                    width_count <= count_buffer;
                end else if (ack) begin
                    req <= 1'b0;
                end
            end
            default: begin
                if (req && ack) begin
                    req <= 1'b0;
                end
            end
        endcase
    end
end

endmodule