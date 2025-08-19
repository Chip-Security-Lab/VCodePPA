//SystemVerilog
module parallel_range_detector(
    input wire clk, rst_n,
    input wire [15:0] data_val,
    input wire [15:0] range_start, range_end,
    output reg lower_than_range,
    output reg inside_range,
    output reg higher_than_range
);

    // 添加数据缓冲寄存器
    reg [15:0] data_val_buf;
    reg [15:0] range_start_buf;
    reg [15:0] range_end_buf;

    // 第一级缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_val_buf <= 16'b0;
            range_start_buf <= 16'b0;
            range_end_buf <= 16'b0;
        end else begin
            data_val_buf <= data_val;
            range_start_buf <= range_start;
            range_end_buf <= range_end;
        end
    end

    // 第二级比较逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lower_than_range <= 1'b0;
            inside_range <= 1'b0;
            higher_than_range <= 1'b0;
        end else begin
            lower_than_range <= (data_val_buf < range_start_buf);
            inside_range <= (data_val_buf >= range_start_buf) && (data_val_buf <= range_end_buf);
            higher_than_range <= (data_val_buf > range_end_buf);
        end
    end

endmodule