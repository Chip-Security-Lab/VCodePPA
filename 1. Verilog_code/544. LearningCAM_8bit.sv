module cam_4 (
    input wire clk,
    input wire rst,         // 添加复位信号
    input wire write_en,
    input wire [7:0] write_data,
    input wire [7:0] read_data,
    output reg match_flag
);
    reg [7:0] data_a, data_b;
    
    always @(posedge clk) begin
        if (rst) begin
            data_a <= 8'b0;
            data_b <= 8'b0;
            match_flag <= 1'b0;
        end else if (write_en) begin
            data_a <= write_data;
            data_b <= write_data;
        end else begin
            match_flag <= (data_a == read_data) || (data_b == read_data);
        end
    end
endmodule