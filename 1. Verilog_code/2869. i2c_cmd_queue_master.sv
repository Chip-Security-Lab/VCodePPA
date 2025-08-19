module i2c_cmd_queue_master #(
    parameter QUEUE_DEPTH = 4
)(
    input clk, reset_n,
    input [7:0] cmd_data,
    input cmd_push, cmd_pop,
    output reg queue_full, queue_empty,
    output reg [7:0] rx_data,
    output reg transfer_done,
    inout scl, sda
);
    reg [7:0] cmd_queue [0:QUEUE_DEPTH-1];
    reg [$clog2(QUEUE_DEPTH):0] head, tail;
    reg [3:0] state;
    reg sda_out, scl_out, sda_en;
    
    // 添加状态定义
    parameter IDLE = 4'b0000;
    parameter START = 4'b0001;
    parameter ADDR = 4'b0010;
    parameter ACK1 = 4'b0011;
    parameter TX_DATA = 4'b0100;
    parameter ACK2 = 4'b0101;
    parameter STOP = 4'b0110;
    
    assign queue_full = ((head + 1) % QUEUE_DEPTH) == tail;
    assign queue_empty = head == tail;
    assign scl = scl_out ? 1'bz : 1'b0;
    assign sda = sda_en ? 1'bz : sda_out;
    
    // 队列管理
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            head <= 0; tail <= 0;
            transfer_done <= 1'b0;
        end else if (cmd_push && !queue_full) begin
            cmd_queue[head] <= cmd_data;
            head <= (head + 1) % QUEUE_DEPTH;
        end else if (cmd_pop && !queue_empty) begin
            tail <= (tail + 1) % QUEUE_DEPTH;
        end
    end
    
    // 添加状态机实现
    reg [3:0] bit_cnt;
    reg [7:0] current_cmd;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            sda_out <= 1'b1;
            scl_out <= 1'b1;
            sda_en <= 1'b1;
            bit_cnt <= 4'b0000;
            transfer_done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (!queue_empty) begin
                        state <= START;
                        current_cmd <= cmd_queue[tail];
                    end
                    sda_out <= 1'b1;
                    scl_out <= 1'b1;
                    sda_en <= 1'b1;
                end
                START: begin
                    sda_out <= 1'b0;
                    sda_en <= 1'b0;
                    state <= ADDR;
                    bit_cnt <= 4'b0000;
                end
                // 其余状态处理省略
                default: state <= IDLE;
            endcase
        end
    end
endmodule