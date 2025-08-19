//SystemVerilog
module crc_auto_reset #(parameter MAX_COUNT=255)(
    input clk, start,
    input [7:0] data_stream,
    output reg [15:0] crc,
    output reg done
);
    reg [8:0] counter;
    wire [15:0] crc_next_value;
    wire high_bit_mask = crc[15] ? 1'b1 : 1'b0;
    wire [15:0] polynomial_mask = {high_bit_mask, high_bit_mask, high_bit_mask, high_bit_mask,
                                  high_bit_mask, high_bit_mask, high_bit_mask, high_bit_mask,
                                  high_bit_mask, high_bit_mask, high_bit_mask, high_bit_mask,
                                  high_bit_mask, high_bit_mask, high_bit_mask, high_bit_mask};
    wire [15:0] polynomial = 16'h8005 & polynomial_mask;
    wire [15:0] shifted_crc = {crc[14:0], 1'b0};
    wire [15:0] data_extended = {8'h00, data_stream};
    
    assign crc_next_value = shifted_crc ^ polynomial ^ data_extended;
    
    always @(posedge clk) begin
        if (start) begin
            counter <= 9'd0;
            crc <= 16'hFFFF;
            done <= 1'b0;
        end else if (counter < MAX_COUNT) begin
            crc <= crc_next_value;
            counter <= counter + 9'd1;
            done <= (counter == MAX_COUNT - 9'd1);
        end
    end
endmodule