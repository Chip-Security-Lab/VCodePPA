//SystemVerilog
module cam_10 (
    input wire clk,
    input wire rst,         // 复位信号
    input wire write_en,    // 写入使能
    input wire [15:0] wide_data_in,
    output reg wide_match,
    output reg [15:0] wide_store_data
);
    // 使用if-else级联结构替代case语句
    always @(posedge clk) begin
        if (rst) begin  // 复位优先，不管write_en是什么值
            wide_store_data <= 16'b0;
            wide_match <= 1'b0;
        end
        else if (write_en) begin  // 非复位状态，写入使能有效
            wide_store_data <= wide_data_in;
        end
        else begin  // 非复位状态，写入使能无效，进行匹配操作
            wide_match <= (wide_store_data == wide_data_in);
        end
    end
endmodule