//SystemVerilog
module hamm_codec(
    input t_clk, t_rst,
    input [3:0] i_data,
    input i_encode_n_decode,
    output reg [6:0] o_encoded,
    output reg [3:0] o_decoded,
    output reg o_error
);
    // 寄存器声明部分
    reg [2:0] r_syndrome;
    // 为高扇出信号添加缓冲寄存器
    reg [3:0] i_data_buf1, i_data_buf2;  // 对输入数据添加两级缓冲
    reg [6:0] o_encoded_buf;             // 对编码结果添加缓冲
    reg [2:0] r_syndrome_buf;            // 对综合码添加缓冲
    
    // 控制信号的多级缓冲
    reg b0, b0_buf1, b0_buf2;
    
    always @(posedge t_clk or posedge t_rst) begin
        if (t_rst) begin
            // 复位所有缓冲寄存器
            i_data_buf1 <= 4'b0;
            i_data_buf2 <= 4'b0;
            o_encoded_buf <= 7'b0;
            r_syndrome_buf <= 3'b0;
            b0 <= 1'b0;
            b0_buf1 <= 1'b0;
            b0_buf2 <= 1'b0;
            
            // 复位输出寄存器
            o_encoded <= 7'b0;
            o_decoded <= 4'b0;
            o_error <= 1'b0;
            r_syndrome <= 3'b0;
        end else begin
            // 对输入数据和控制信号进行多级缓冲
            i_data_buf1 <= i_data;
            i_data_buf2 <= i_data_buf1;
            b0 <= i_encode_n_decode;
            b0_buf1 <= b0;
            b0_buf2 <= b0_buf1;
            
            // 编码和解码操作
            if (b0_buf2) begin
                // 编码操作，使用缓冲后的输入数据
                o_encoded[0] <= i_data_buf2[0] ^ i_data_buf2[1] ^ i_data_buf2[3];
                o_encoded[1] <= i_data_buf2[0] ^ i_data_buf2[2] ^ i_data_buf2[3];
                o_encoded[2] <= i_data_buf2[0];
                o_encoded[3] <= i_data_buf2[1] ^ i_data_buf2[2] ^ i_data_buf2[3];
                o_encoded[4] <= i_data_buf2[1];
                o_encoded[5] <= i_data_buf2[2];
                o_encoded[6] <= i_data_buf2[3];
                
                // 将编码结果缓存到缓冲寄存器
                o_encoded_buf <= o_encoded;
            end else begin
                // 解码操作
                // 计算综合码并缓存
                r_syndrome[0] <= o_encoded_buf[0] ^ o_encoded_buf[2] ^ o_encoded_buf[4] ^ o_encoded_buf[6];
                r_syndrome[1] <= o_encoded_buf[1] ^ o_encoded_buf[2] ^ o_encoded_buf[5] ^ o_encoded_buf[6];
                r_syndrome[2] <= o_encoded_buf[3] ^ o_encoded_buf[4] ^ o_encoded_buf[5] ^ o_encoded_buf[6];
                
                // 缓存综合码
                r_syndrome_buf <= r_syndrome;
                
                // 使用缓冲的综合码检查错误
                o_error <= |r_syndrome_buf;
                
                // 使用缓冲的编码结果进行解码
                o_decoded <= {o_encoded_buf[6], o_encoded_buf[5], o_encoded_buf[4], o_encoded_buf[2]};
            end
        end
    end
endmodule