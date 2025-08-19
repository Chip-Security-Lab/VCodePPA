module CAN_Monitor_Error_Detect #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input can_rx,
    input can_tx,
    output reg form_error,
    output reg ack_error,
    output reg crc_error
);
    reg [6:0] bit_counter;
    reg [14:0] crc_calc;
    reg [14:0] crc_received;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0;
            crc_calc <= 0;
            crc_received <= 0;
        end else begin
            bit_counter <= bit_counter + 1;
            
            // CRC calculation
            crc_calc <= {crc_calc[13:0], 1'b0} ^ 
                       ((crc_calc[14] ^ can_rx) ? 15'h4599 : 15'h0);
            
            if (bit_counter == 95) crc_received <= {crc_received[13:0], can_rx};
            
            // Error detection
            form_error <= (can_rx && can_tx);
            ack_error <= (bit_counter == 96) && !can_tx;
            crc_error <= (bit_counter == 97) && (crc_calc != crc_received);
        end
    end
endmodule