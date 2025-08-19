module cam_2 (
    input wire clk,
    input wire rst,         // 添加复位信号
    input wire write_en,    // 添加写入使能
    input wire [1:0] write_addr, // 写入哪个位置
    input wire [7:0] in_data,
    output reg [3:0] cam_address,
    output reg cam_valid
);
    reg [7:0] data0, data1, data2, data3;
    
    // 添加写入逻辑
    always @(posedge clk) begin
        if (rst) begin
            data0 <= 8'b0;
            data1 <= 8'b0;
            data2 <= 8'b0;
            data3 <= 8'b0;
            cam_address <= 4'h0;
            cam_valid <= 1'b0;
        end else if (write_en) begin
            case (write_addr)
                2'b00: data0 <= in_data;
                2'b01: data1 <= in_data;
                2'b10: data2 <= in_data;
                2'b11: data3 <= in_data;
            endcase
        end else begin
            // 优先级匹配逻辑，检查所有条目
            if (data0 == in_data) begin
                cam_address <= 4'h0;
                cam_valid <= 1'b1;
            end else if (data1 == in_data) begin
                cam_address <= 4'h1;
                cam_valid <= 1'b1;
            end else if (data2 == in_data) begin
                cam_address <= 4'h2;
                cam_valid <= 1'b1;
            end else if (data3 == in_data) begin
                cam_address <= 4'h3;
                cam_valid <= 1'b1;
            end else begin
                cam_valid <= 1'b0;
                cam_address <= 4'h0;
            end
        end
    end
endmodule