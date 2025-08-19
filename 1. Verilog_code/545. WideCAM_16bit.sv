module cam_5 (
    input wire clk,
    input wire rst,         // 添加复位信号
    input wire write_en,    // 添加写入使能
    input wire [15:0] input_data,
    output reg match,
    output reg [15:0] stored_data
);
    always @(posedge clk) begin
        if (rst) begin
            stored_data <= 16'b0;
            match <= 1'b0;
        end else if (write_en) begin
            stored_data <= input_data;
        end else begin
            match <= (stored_data == input_data);
        end
    end
endmodule