module eth_jumbo_frame_handler #(
    parameter STD_FRAME_SIZE = 1518,  // Standard Ethernet frame size
    parameter JUMBO_FRAME_SIZE = 9000 // Jumbo frame size limit
) (
    input wire clk,
    input wire reset,
    // Data input interface
    input wire [7:0] rx_data,
    input wire rx_valid,
    input wire frame_start,
    input wire frame_end,
    // Data output interface
    output reg [7:0] tx_data,
    output reg tx_valid,
    output reg frame_too_large,
    output reg jumbo_frame_detected
);
    reg [13:0] byte_counter;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_data <= 8'h00;
            tx_valid <= 1'b0;
            frame_too_large <= 1'b0;
            jumbo_frame_detected <= 1'b0;
            byte_counter <= 14'd0;
        end else begin
            if (frame_start) begin
                byte_counter <= 14'd0;
                frame_too_large <= 1'b0;
                jumbo_frame_detected <= 1'b0;
            end
            
            if (rx_valid) begin
                byte_counter <= byte_counter + 1'b1;
                
                // Check frame size thresholds
                if (byte_counter == STD_FRAME_SIZE)
                    jumbo_frame_detected <= 1'b1;
                    
                if (byte_counter >= JUMBO_FRAME_SIZE)
                    frame_too_large <= 1'b1;
                
                // Pass through data if not too large
                if (!frame_too_large) begin
                    tx_data <= rx_data;
                    tx_valid <= 1'b1;
                end else begin
                    tx_valid <= 1'b0;
                end
            end else begin
                tx_valid <= 1'b0;
            end
            
            if (frame_end) begin
                tx_valid <= 1'b0;
            end
        end
    end
endmodule