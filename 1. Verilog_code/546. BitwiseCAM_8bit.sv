module cam_6 (
    input wire clk,
    input wire rst,         // 添加复位信号
    input wire write_en,    // 添加写入使能
    input wire [7:0] data_in,
    output reg match_flag
);
    reg [7:0] stored_bits;
    
    // 添加复位和写入控制
    always @(posedge clk) begin
        if (rst) begin
            stored_bits <= 8'b0;
            match_flag <= 1'b0;
        end else if (write_en) begin
            stored_bits <= data_in;
        end else begin
            // 移除不可综合的break语句，使用规约操作符
            match_flag <= &(~(stored_bits ^ data_in));
        end
    end
endmodule