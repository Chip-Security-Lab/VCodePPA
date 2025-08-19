module eth_broadcast_filter (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire frame_start,
    output reg [7:0] data_out,
    output reg data_valid_out,
    output reg broadcast_detected,
    input wire pass_broadcast
);
    reg [5:0] byte_counter;
    reg broadcast_frame;
    reg [47:0] dest_mac;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_counter <= 6'd0;
            broadcast_frame <= 1'b0;
            broadcast_detected <= 1'b0;
            data_valid_out <= 1'b0;
            dest_mac <= 48'd0;
        end else begin
            data_out <= data_in;
            
            if (frame_start) begin
                byte_counter <= 6'd0;
                broadcast_frame <= 1'b0;
                broadcast_detected <= 1'b0;
            end
            
            if (data_valid) begin
                if (byte_counter < 6) begin
                    // Capture destination MAC address (first 6 bytes)
                    dest_mac <= {dest_mac[39:0], data_in};
                    byte_counter <= byte_counter + 1'b1;
                    
                    // Check if this byte is 0xFF (part of broadcast address)
                    if (data_in != 8'hFF) begin
                        broadcast_frame <= 1'b0;
                    end else if (byte_counter == 0) begin
                        // First byte is 0xFF, could be broadcast
                        broadcast_frame <= 1'b1;
                    end
                    
                    // Only output data if we're passing broadcasts or it's not a broadcast frame
                    data_valid_out <= (pass_broadcast || !broadcast_frame);
                end else begin
                    if (byte_counter == 6 && broadcast_frame) begin
                        // Completed reading destination MAC and it's all FF's
                        broadcast_detected <= 1'b1;
                    end
                    
                    // Only output data if we're passing broadcasts or it's not a broadcast frame
                    data_valid_out <= (pass_broadcast || !broadcast_detected);
                end
            end else begin
                data_valid_out <= 1'b0;
            end
        end
    end
endmodule