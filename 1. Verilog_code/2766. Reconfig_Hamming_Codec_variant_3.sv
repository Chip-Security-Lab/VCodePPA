//SystemVerilog
module Reconfig_Hamming_Codec(
    input clk,
    input [1:0] config_mode,
    input [31:0] data_in,
    output reg [31:0] data_out
);
    // 为高扇出信号添加缓冲寄存器
    reg [31:0] data_in_buf1, data_in_buf2;
    reg [1:0] config_mode_buf;
    reg [31:0] data_out_next;
    
    // 输入缓冲，将高扇出信号分阶段处理
    always @(posedge clk) begin
        data_in_buf1 <= data_in;
        data_in_buf2 <= data_in_buf1;
        config_mode_buf <= config_mode;
    end
    
    // 编码逻辑 - 将组合逻辑单独处理
    always @(*) begin
        case(config_mode_buf)
            2'b00: begin // (7,4)码
                data_out_next[6:0] = {data_in_buf1[3:0], ^data_in_buf1[3:0], 
                                      data_in_buf1[3]^data_in_buf1[2], 
                                      data_in_buf1[3]^data_in_buf1[1]};
                data_out_next[31:7] = data_in_buf1[31:4];
            end
            2'b01: begin // (15,11)码
                data_out_next[14:0] = {data_in_buf1[10:0], 
                                      ^data_in_buf1[10:0],
                                      data_in_buf1[10]^data_in_buf1[9]^data_in_buf1[6]^data_in_buf1[5]^data_in_buf1[3]^data_in_buf1[0],
                                      data_in_buf1[10]^data_in_buf1[8]^data_in_buf1[7]^data_in_buf1[5]^data_in_buf1[4]^data_in_buf1[1],
                                      data_in_buf1[9]^data_in_buf1[8]^data_in_buf1[7]^data_in_buf1[3]^data_in_buf1[2]^data_in_buf1[0]};
                data_out_next[31:15] = data_in_buf1[31:11];
            end
            2'b10: begin // (31,26)码
                // 使用中间变量减少扇出
                data_out_next[30:0] = {data_in_buf2[25:0], 
                                      ^data_in_buf2[25:0],
                                      ^{data_in_buf2[25:20], data_in_buf2[15:10], data_in_buf2[5:0]},
                                      ^{data_in_buf2[25:16], data_in_buf2[10:1]},
                                      ^{data_in_buf2[25:21], data_in_buf2[15:11], data_in_buf2[5:1]},
                                      ^{data_in_buf2[20:16], data_in_buf2[10:6], data_in_buf2[0]}};
                data_out_next[31] = data_in_buf2[31:26] != 0;
            end
            2'b11: begin // SECDED
                data_out_next[31:0] = {data_in_buf1[30:0], ^data_in_buf1[30:0]};
            end
            default: begin
                data_out_next = 32'b0;
            end
        endcase
    end
    
    // 输出缓冲，采用两级流水线结构减少关键路径延迟
    always @(posedge clk) begin
        data_out <= data_out_next;
    end
    
endmodule