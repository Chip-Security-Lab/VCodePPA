module cam_10 (
    input wire clk,
    input wire rst,         // 添加复位信号
    input wire write_en,    // 添加写入使能
    input wire [15:0] wide_data_in,
    output reg wide_match,
    output reg [15:0] wide_store_data
);
    // 添加复位和写入控制
    always @(posedge clk) begin
        if (rst) begin
            wide_store_data <= 16'b0;
            wide_match <= 1'b0;
        end else if (write_en) begin
            wide_store_data <= wide_data_in;
        end else begin
            wide_match <= (wide_store_data == wide_data_in);
        end
    end
endmodule