module cam_1 (
    input wire clk,
    input wire rst,         // 添加复位信号
    input wire write_en,    // 添加写入使能
    input wire [7:0] data_in,
    output reg match_flag,
    output reg [7:0] store_data
);
    // 添加复位和写入控制
    always @(posedge clk) begin
        if (rst) begin
            store_data <= 8'b0;
            match_flag <= 1'b0;
        end else if (write_en) begin
            store_data <= data_in;
        end else begin
            match_flag <= (store_data == data_in);
        end
    end
endmodule