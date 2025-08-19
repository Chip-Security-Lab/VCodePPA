//SystemVerilog
module crc_config_xor #(
    parameter WIDTH = 16,
    parameter INIT = 16'hFFFF,
    parameter FINAL_XOR = 16'h0000
)(
    input clk, en, 
    input [WIDTH-1:0] data,
    output [WIDTH-1:0] crc_result,
    output reg [WIDTH-1:0] crc
);

    // 缓冲寄存器
    reg [WIDTH-1:0] crc_buf1, crc_buf2;
    reg crc_msb_buf;
    reg [15:0] poly_term;
    reg [WIDTH-1:0] crc_out_buf;
    reg [WIDTH-1:0] crc_next;
    reg [WIDTH-1:0] shift_result;
    reg [WIDTH-1:0] xor_result;

    // 移位操作
    always @(posedge clk) begin
        shift_result <= crc_buf1 << 1;
    end

    // 异或操作
    always @(posedge clk) begin
        xor_result <= data ^ poly_term;
    end

    // CRC计算
    always @(posedge clk) begin
        crc_next <= shift_result ^ xor_result;
    end

    // 主状态更新
    always @(posedge clk) begin
        if (en) begin
            crc <= crc_next;
        end else begin
            crc <= INIT;
        end
    end

    // 缓冲更新
    always @(posedge clk) begin
        crc_buf1 <= crc;
        crc_buf2 <= crc;
        crc_msb_buf <= crc[WIDTH-1];
    end

    // 多项式项计算
    always @(posedge clk) begin
        poly_term <= crc_msb_buf ? 16'h1021 : 16'h0000;
    end

    // 最终输出
    always @(posedge clk) begin
        crc_out_buf <= crc_buf2 ^ FINAL_XOR;
    end
    
    assign crc_result = crc_out_buf;
    
endmodule