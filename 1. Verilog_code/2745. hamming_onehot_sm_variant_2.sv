//SystemVerilog
module hamming_onehot_sm(
    input clk, rst, start,
    input [3:0] data_in,
    output reg [6:0] encoded,
    output reg done
);

    // 状态定义
    reg [3:0] state, next_state;
    parameter S_IDLE = 4'b0001, S_CALC = 4'b0010, S_WRITE = 4'b0100, S_DONE = 4'b1000;
    
    // 预计算校验位
    wire p0, p1, p2;
    assign p0 = data_in[0] ^ data_in[1] ^ data_in[3];
    assign p1 = data_in[0] ^ data_in[2] ^ data_in[3];
    assign p2 = data_in[1] ^ data_in[2] ^ data_in[3];

    // 状态转换逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 次态逻辑 - 简化条件判断
    wire calc_ready = (state == S_CALC);
    wire write_ready = (state == S_WRITE);
    wire done_ready = (state == S_DONE);
    
    always @(*) begin
        case (1'b1)
            (state == S_IDLE): next_state = start ? S_CALC : S_IDLE;
            calc_ready: next_state = S_WRITE;
            write_ready: next_state = S_DONE;
            done_ready: next_state = S_IDLE;
            default: next_state = S_IDLE;
        endcase
    end
    
    // 编码计算逻辑 - 使用预计算的校验位
    reg [6:0] encoded_next;
    always @(*) begin
        encoded_next = encoded;
        if (state == S_CALC) begin
            encoded_next = {data_in[3], data_in[2], data_in[1], p2, data_in[0], p1, p0};
        end
    end
    
    // 输出寄存器更新逻辑 - 简化状态判断
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            done <= 1'b0;
        end else begin
            if (calc_ready) encoded <= encoded_next;
            if (done_ready) done <= 1'b1;
            if (state == S_IDLE) done <= 1'b0;
        end
    end

endmodule