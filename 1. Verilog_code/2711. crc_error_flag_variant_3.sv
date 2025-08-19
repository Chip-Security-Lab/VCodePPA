//SystemVerilog
// CRC计算子模块
module crc16_calculator (
    input clk,
    input rst,
    input [15:0] data_in,
    output reg [15:0] current_crc
);

    always @(posedge clk) begin
        if (rst) begin
            current_crc <= 16'hFFFF;
        end else begin
            current_crc <= crc16_update(current_crc, data_in);
        end
    end

    function [15:0] crc16_update;
        input [15:0] crc, data;
        begin
            crc16_update = {crc[14:0], 1'b0} ^ 
                          (crc[15] ^ data[15] ? 16'h1021 : 0);
        end
    endfunction

endmodule

// 错误检测子模块
module error_detector (
    input clk,
    input rst,
    input [15:0] current_crc,
    input [15:0] expected_crc,
    output reg error_flag
);

    always @(posedge clk) begin
        if (rst) begin
            error_flag <= 0;
        end else begin
            error_flag <= (current_crc != expected_crc);
        end
    end

endmodule

// 顶层模块
module crc_error_flag (
    input clk,
    input rst,
    input [15:0] data_in,
    input [15:0] expected_crc,
    output error_flag
);

    wire [15:0] current_crc;

    crc16_calculator crc_calc (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .current_crc(current_crc)
    );

    error_detector err_detect (
        .clk(clk),
        .rst(rst),
        .current_crc(current_crc),
        .expected_crc(expected_crc),
        .error_flag(error_flag)
    );

endmodule