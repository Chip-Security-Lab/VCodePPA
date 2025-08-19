module usb_packet_error_checker(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire packet_end,
    input wire [15:0] received_crc,
    output reg crc_error,
    output reg timeout_error,
    output reg bitstuff_error
);
    reg [15:0] calculated_crc;
    reg [7:0] timeout_counter;
    reg receiving;
    
    // Simplified CRC-16 calculation
    wire [15:0] next_crc = {calculated_crc[14:0], 1'b0} ^ 
                          (calculated_crc[15] ? 16'h8005 : 16'h0000);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            calculated_crc <= 16'hFFFF;
            timeout_counter <= 8'd0;
            crc_error <= 1'b0;
            timeout_error <= 1'b0;
            bitstuff_error <= 1'b0;
            receiving <= 1'b0;
        end else begin
            if (data_valid) begin
                calculated_crc <= calculated_crc ^ {8'h00, data_in};
                timeout_counter <= 8'd0;
                receiving <= 1'b1;
            end else if (receiving) begin
                timeout_counter <= timeout_counter + 1'b1;
                if (timeout_counter > 8'd200) begin
                    timeout_error <= 1'b1;
                    receiving <= 1'b0;
                end
            end
            
            if (packet_end) begin
                crc_error <= (calculated_crc != received_crc);
                calculated_crc <= 16'hFFFF;
                receiving <= 1'b0;
            end
        end
    end
endmodule