//SystemVerilog
module compact_hamming(
    input i_clk, i_rst, i_en,
    input [3:0] i_data,
    output reg [6:0] o_code
);
    // 寄存器缓冲高扇出信号i_data
    reg [3:0] data_buf1, data_buf2;
    
    // 第一级缓冲器
    always @(posedge i_clk) begin
        if (i_rst) begin
            data_buf1 <= 4'b0;
            data_buf2 <= 4'b0;
        end
        else if (i_en) begin
            data_buf1 <= i_data;
            data_buf2 <= i_data;
        end
    end
    
    // 计算奇偶校验位
    reg p1, p2, p3;
    
    always @(posedge i_clk) begin
        if (i_rst) begin
            p1 <= 1'b0;
            p2 <= 1'b0;
            p3 <= 1'b0;
        end
        else if (i_en) begin
            p1 <= ^{data_buf1[1], data_buf1[2], data_buf1[3]};
            p2 <= ^{data_buf1[0], data_buf1[2], data_buf1[3]};
            p3 <= ^{data_buf2[0], data_buf2[1], data_buf2[3]};
        end
    end
    
    // 最终输出
    always @(posedge i_clk) begin
        if (i_rst) begin
            o_code <= 7'b0;
        end
        else if (i_en) begin
            o_code <= {data_buf2[3:1], p1, data_buf2[0], p2, p3};
        end
    end
endmodule