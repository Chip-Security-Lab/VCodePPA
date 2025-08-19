module crc_error_injection (
    input clk, inject_err,
    input [7:0] data_in,
    output reg [15:0] crc
);
    wire [7:0] real_data = inject_err ? ~data_in : data_in;
    
    // 实现CRC16计算函数
    function [15:0] crc16;
        input [7:0] data;
        input [15:0] crc_in;
        reg [15:0] crc_out;
        integer i;
        begin
            crc_out = crc_in;
            for (i = 0; i < 8; i = i + 1) begin
                if ((data[i] ^ crc_out[15]) == 1'b1)
                    crc_out = {crc_out[14:0], 1'b0} ^ 16'h8005;
                else
                    crc_out = {crc_out[14:0], 1'b0};
            end
            crc16 = crc_out;
        end
    endfunction

    always @(posedge clk) begin
        crc <= crc16(real_data, crc);
    end
endmodule