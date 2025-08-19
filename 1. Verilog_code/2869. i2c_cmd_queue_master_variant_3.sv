//SystemVerilog
//IEEE 1364-2005 Verilog
module i2c_cmd_queue_master #(
    parameter QUEUE_DEPTH = 4
)(
    input clk, reset_n,
    input [7:0] cmd_data,
    input cmd_push, cmd_pop,
    output queue_full, queue_empty,
    output reg [7:0] rx_data,
    output reg transfer_done,
    inout scl, sda
);
    // 参数定义
    localparam IDLE  = 4'b0000;
    localparam START = 4'b0001;
    localparam ADDR  = 4'b0010;
    localparam ACK1  = 4'b0011;
    localparam TX_DATA = 4'b0100;
    localparam ACK2  = 4'b0101;
    localparam STOP  = 4'b0110;
    
    // 内部寄存器
    reg [7:0] cmd_queue [0:QUEUE_DEPTH-1];
    reg [$clog2(QUEUE_DEPTH):0] head, tail;
    // 为高扇出信号head添加缓冲寄存器
    reg [$clog2(QUEUE_DEPTH):0] head_buf1, head_buf2;
    // 为高扇出信号tail添加缓冲寄存器
    reg [$clog2(QUEUE_DEPTH):0] tail_buf1, tail_buf2;
    
    reg [3:0] state, next_state;
    // 为高扇出信号next_state添加缓冲寄存器
    reg [3:0] next_state_buf1, next_state_buf2;
    
    reg sda_out, scl_out, sda_en;
    reg [3:0] bit_cnt, next_bit_cnt;
    // 为高扇出信号next_bit_cnt添加缓冲寄存器
    reg [3:0] next_bit_cnt_buf;
    
    reg [7:0] current_cmd, next_current_cmd;
    // 为高扇出信号next_current_cmd添加缓冲寄存器
    reg [7:0] next_current_cmd_buf1, next_current_cmd_buf2;
    
    reg transfer_done_next;
    
    // 组合逻辑 - 状态输出和下一状态
    wire [$clog2(QUEUE_DEPTH):0] next_head, next_tail;
    wire should_push, should_pop;
    
    // 组合逻辑 - 队列状态 - 使用缓冲的head和tail
    assign queue_full = ((head_buf1 + 1) % QUEUE_DEPTH) == tail_buf1;
    assign queue_empty = head_buf2 == tail_buf2;
    
    // 组合逻辑 - I2C信号驱动
    assign scl = scl_out ? 1'bz : 1'b0;
    assign sda = sda_en ? 1'bz : sda_out;
    
    // 组合逻辑 - 队列操作控制
    assign should_push = cmd_push && !queue_full;
    assign should_pop = cmd_pop && !queue_empty;
    assign next_head = should_push ? (head + 1) % QUEUE_DEPTH : head;
    assign next_tail = should_pop ? (tail + 1) % QUEUE_DEPTH : tail;
    
    // 缓冲寄存器更新 - 高扇出信号的多级缓冲
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            head_buf1 <= 0;
            head_buf2 <= 0;
            tail_buf1 <= 0;
            tail_buf2 <= 0;
            next_state_buf1 <= IDLE;
            next_state_buf2 <= IDLE;
            next_bit_cnt_buf <= 4'b0000;
            next_current_cmd_buf1 <= 8'h00;
            next_current_cmd_buf2 <= 8'h00;
        end else begin
            // 更新head缓冲
            head_buf1 <= head;
            head_buf2 <= head_buf1;
            
            // 更新tail缓冲
            tail_buf1 <= tail;
            tail_buf2 <= tail_buf1;
            
            // 更新next_state缓冲
            next_state_buf1 <= next_state;
            next_state_buf2 <= next_state_buf1;
            
            // 更新next_bit_cnt缓冲
            next_bit_cnt_buf <= next_bit_cnt;
            
            // 更新next_current_cmd缓冲
            next_current_cmd_buf1 <= next_current_cmd;
            next_current_cmd_buf2 <= next_current_cmd_buf1;
        end
    end
    
    // 组合逻辑 - 下一状态计算
    always @(*) begin
        // 默认保持当前状态
        next_state = state;
        next_bit_cnt = bit_cnt;
        next_current_cmd = current_cmd;
        transfer_done_next = transfer_done;
        
        case (state)
            IDLE: begin
                if (!queue_empty) begin
                    next_state = START;
                    next_current_cmd = cmd_queue[tail];
                end
            end
            START: begin
                next_state = ADDR;
                next_bit_cnt = 4'b0000;
            end
            // 其他状态的组合逻辑转换...
            default: next_state = IDLE;
        endcase
    end
    
    // 时序逻辑 - 寄存器更新
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            head <= 0;
            tail <= 0;
            transfer_done <= 1'b0;
        end else begin
            // 队列指针更新
            head <= next_head;
            tail <= next_tail;
            transfer_done <= transfer_done_next;
            
            // 命令入队
            if (should_push) begin
                cmd_queue[head] <= cmd_data;
            end
        end
    end
    
    // 时序逻辑 - 状态机
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            bit_cnt <= 4'b0000;
            current_cmd <= 8'h00;
            sda_out <= 1'b1;
            scl_out <= 1'b1;
            sda_en <= 1'b1;
        end else begin
            // 使用缓冲后的控制信号
            state <= next_state_buf1;
            bit_cnt <= next_bit_cnt_buf;
            current_cmd <= next_current_cmd_buf1;
            
            // I2C信号输出控制 - 使用缓冲的next_state减少关键路径延迟
            case (next_state_buf2)
                IDLE: begin
                    sda_out <= 1'b1;
                    scl_out <= 1'b1;
                    sda_en <= 1'b1;
                end
                START: begin
                    sda_out <= 1'b0;
                    sda_en <= 1'b0;
                end
                // 其他状态的时序逻辑...
            endcase
        end
    end
    
endmodule