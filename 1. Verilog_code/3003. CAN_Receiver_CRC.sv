module CAN_Receiver_CRC #(
    parameter DATA_WIDTH = 8,
    parameter CRC_WIDTH = 15
)(
    input clk,
    input rst_n,
    input can_rx,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg crc_error,
    output reg frame_valid
);
    reg [CRC_WIDTH-1:0] crc_reg;
    reg [3:0] bit_cnt;
    reg [DATA_WIDTH-1:0] shift_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_reg <= 15'h0000;
            bit_cnt <= 0;
            shift_reg <= 0;
            crc_error <= 0;
            frame_valid <= 0;
        end else begin
            if (bit_cnt < DATA_WIDTH) begin
                shift_reg <= {shift_reg[DATA_WIDTH-2:0], can_rx};
                crc_reg <= (crc_reg << 1) ^ (can_rx ? 16'h4599 : 16'h0000);
                bit_cnt <= bit_cnt + 1;
            end else begin
                frame_valid <= (crc_reg == 16'h0000);
                crc_error <= (crc_reg != 16'h0000);
                bit_cnt <= 0;
                rx_data <= shift_reg;
            end
        end
    end
endmodule