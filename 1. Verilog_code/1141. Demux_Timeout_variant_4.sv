//SystemVerilog
module Demux_Timeout #(parameter DW=8, TIMEOUT=100) (
    input clk, rst,
    input valid,
    input [DW-1:0] data_in,
    input [3:0] addr,
    output reg [15:0][DW-1:0] data_out,
    output reg timeout
);
    reg [7:0] counter;
    reg [7:0] counter_buf1, counter_buf2, counter_buf3, counter_buf4;
    reg timeout_pre;
    
    // 先行借位减法器信号
    wire [7:0] remaining_time;
    wire [7:0] borrow;
    
    // 生成借位信号
    assign borrow[0] = (counter[0] < TIMEOUT[0]);
    assign borrow[1] = (counter[1] < TIMEOUT[1]) | ((counter[1] == TIMEOUT[1]) & borrow[0]);
    assign borrow[2] = (counter[2] < TIMEOUT[2]) | ((counter[2] == TIMEOUT[2]) & borrow[1]);
    assign borrow[3] = (counter[3] < TIMEOUT[3]) | ((counter[3] == TIMEOUT[3]) & borrow[2]);
    assign borrow[4] = (counter[4] < TIMEOUT[4]) | ((counter[4] == TIMEOUT[4]) & borrow[3]);
    assign borrow[5] = (counter[5] < TIMEOUT[5]) | ((counter[5] == TIMEOUT[5]) & borrow[4]);
    assign borrow[6] = (counter[6] < TIMEOUT[6]) | ((counter[6] == TIMEOUT[6]) & borrow[5]);
    assign borrow[7] = (counter[7] < TIMEOUT[7]) | ((counter[7] == TIMEOUT[7]) & borrow[6]);
    
    // 计算剩余时间 (TIMEOUT - counter)
    assign remaining_time[0] = TIMEOUT[0] ^ counter[0] ^ borrow[0];
    assign remaining_time[1] = TIMEOUT[1] ^ counter[1] ^ borrow[0];
    assign remaining_time[2] = TIMEOUT[2] ^ counter[2] ^ borrow[1];
    assign remaining_time[3] = TIMEOUT[3] ^ counter[3] ^ borrow[2];
    assign remaining_time[4] = TIMEOUT[4] ^ counter[4] ^ borrow[3];
    assign remaining_time[5] = TIMEOUT[5] ^ counter[5] ^ borrow[4];
    assign remaining_time[6] = TIMEOUT[6] ^ counter[6] ^ borrow[5];
    assign remaining_time[7] = TIMEOUT[7] ^ counter[7] ^ borrow[6];
    
    // 判断是否达到超时条件
    wire is_timeout = (remaining_time == 8'd1);
    wire is_max = (remaining_time == 8'd0);
    
    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            counter_buf1 <= 0;
            counter_buf2 <= 0;
            counter_buf3 <= 0;
            counter_buf4 <= 0;
            timeout_pre <= 0;
            timeout <= 0;
            data_out <= 0;
        end else begin
            case (valid)
                1'b1: begin
                    counter <= 0;
                    counter_buf1 <= 0;
                    counter_buf2 <= 0;
                    counter_buf3 <= 0;
                    counter_buf4 <= 0;
                    timeout_pre <= 0;
                    timeout <= 0;
                    data_out[addr] <= data_in;
                end
                
                1'b0: begin
                    counter <= is_max ? counter : counter + 1;
                    
                    // 缓冲寄存器传播counter值，分散负载
                    counter_buf1 <= counter;
                    counter_buf2 <= counter;
                    counter_buf3 <= counter;
                    counter_buf4 <= counter;
                    
                    // 使用先行借位减法器判断超时条件
                    timeout_pre <= is_timeout;
                    timeout <= timeout_pre;
                    
                    // 使用case语句替代if条件级联结构清零数据
                    case (timeout_pre)
                        1'b1: begin
                            data_out[15:0] <= 0;
                        end
                        default: begin
                            // 保持数据不变
                        end
                    endcase
                end
            endcase
        end
    end
endmodule