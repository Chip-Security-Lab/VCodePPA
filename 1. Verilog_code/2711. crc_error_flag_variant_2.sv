//SystemVerilog
module crc_error_flag (
    input clk, rst,
    input [15:0] data_in, expected_crc,
    input req,
    output reg ack,
    output reg error_flag
);
    reg [15:0] current_crc;
    reg data_processed;
    
    always @(posedge clk) begin
        if (rst) begin
            current_crc <= 16'hFFFF;
            error_flag <= 0;
            ack <= 0;
            data_processed <= 0;
        end else begin
            if (req && !data_processed) begin
                current_crc <= crc16_update(current_crc, data_in);
                error_flag <= (current_crc != expected_crc);
                ack <= 1;
                data_processed <= 1;
            end else if (!req) begin
                ack <= 0;
                data_processed <= 0;
            end
        end
    end

    function [15:0] crc16_update;
        input [15:0] crc, data;
        reg [15:0] polynomial;
        begin
            polynomial = 16'h1021;
            crc16_update = {crc[14:0], 1'b0} ^ 
                          ((crc[15] ^ data[15]) ? polynomial : 16'h0000);
        end
    endfunction
endmodule