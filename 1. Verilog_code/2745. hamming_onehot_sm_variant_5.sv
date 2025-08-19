//SystemVerilog
module hamming_onehot_sm(
    input clk, rst, start,
    input [3:0] data_in,
    output reg [6:0] encoded,
    output reg done
);
    // 使用one-hot编码，只需要3位就可以表示4个状态
    reg [2:0] state;
    parameter S_IDLE = 3'b001, S_CALC = 3'b010, S_DONE = 3'b100;
    
    // 优化的奇偶校验位计算
    wire p1, p2, p4;
    assign p1 = data_in[0] ^ data_in[1] ^ data_in[3];
    assign p2 = data_in[0] ^ data_in[2] ^ data_in[3];
    assign p4 = data_in[1] ^ data_in[2] ^ data_in[3];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            encoded <= 7'b0;
            done <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        state <= S_CALC;
                        // 在一个周期内完成数据编码和写入
                        encoded <= {data_in[3], data_in[2], data_in[1], p4, 
                                   data_in[0], p2, p1};
                    end
                end
                
                S_CALC: begin
                    state <= S_DONE;
                end
                
                S_DONE: begin
                    done <= 1'b1;
                    state <= S_IDLE;
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule