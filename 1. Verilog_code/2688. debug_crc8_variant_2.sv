//SystemVerilog
module debug_crc8(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data,
    input wire valid,
    output reg [7:0] crc_out,
    output reg error_detected,
    output reg [3:0] bit_position,
    output reg processing_active
);
    parameter [7:0] POLY = 8'h07;
    
    // Buffer registers for high fanout signals
    reg [7:0] crc_out_buf;
    reg [7:0] crc_out_buf2;
    reg [7:0] crc_out_buf3;
    
    // CRC calculation logic
    wire [7:0] crc_next = {crc_out[6:0], 1'b0} ^ ((crc_out[7] ^ data[0]) ? POLY : 8'h0);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_out <= 8'h00;
            crc_out_buf <= 8'h00;
            crc_out_buf2 <= 8'h00;
            crc_out_buf3 <= 8'h00;
            error_detected <= 1'b0;
            bit_position <= 4'd0;
            processing_active <= 1'b0;
        end else if (valid) begin
            processing_active <= 1'b1;
            crc_out <= crc_next;
            crc_out_buf <= crc_next;
            crc_out_buf2 <= crc_out_buf;
            crc_out_buf3 <= crc_out_buf2;
            bit_position <= bit_position + 1;
            error_detected <= (crc_out_buf3 != 8'h00) && (bit_position == 4'd7);
        end else begin
            processing_active <= 1'b0;
        end
    end
endmodule