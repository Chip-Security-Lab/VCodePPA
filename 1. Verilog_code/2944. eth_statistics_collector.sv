module eth_statistics_collector #(parameter COUNTER_WIDTH = 32) (
    input wire clk,
    input wire rst_n,
    input wire rx_valid,
    input wire [7:0] rx_data,
    input wire frame_start,
    input wire frame_end,
    input wire crc_error,
    input wire length_error,
    output reg [COUNTER_WIDTH-1:0] total_bytes,
    output reg [COUNTER_WIDTH-1:0] total_frames,
    output reg [COUNTER_WIDTH-1:0] crc_error_frames,
    output reg [COUNTER_WIDTH-1:0] length_error_frames,
    output reg [COUNTER_WIDTH-1:0] broadcast_frames,
    output reg [COUNTER_WIDTH-1:0] multicast_frames
);
    reg frame_in_progress;
    reg [COUNTER_WIDTH-1:0] current_frame_bytes;
    reg is_broadcast, is_multicast;
    reg [2:0] byte_count;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_bytes <= {COUNTER_WIDTH{1'b0}};
            total_frames <= {COUNTER_WIDTH{1'b0}};
            crc_error_frames <= {COUNTER_WIDTH{1'b0}};
            length_error_frames <= {COUNTER_WIDTH{1'b0}};
            broadcast_frames <= {COUNTER_WIDTH{1'b0}};
            multicast_frames <= {COUNTER_WIDTH{1'b0}};
            
            frame_in_progress <= 1'b0;
            current_frame_bytes <= {COUNTER_WIDTH{1'b0}};
            is_broadcast <= 1'b0;
            is_multicast <= 1'b0;
            byte_count <= 3'd0;
        end else begin
            if (frame_start) begin
                frame_in_progress <= 1'b1;
                current_frame_bytes <= {COUNTER_WIDTH{1'b0}};
                is_broadcast <= 1'b1; // Assume broadcast until proven otherwise
                is_multicast <= 1'b0;
                byte_count <= 3'd0;
            end
            
            if (rx_valid && frame_in_progress) begin
                current_frame_bytes <= current_frame_bytes + 1'b1;
                
                // Check first 6 bytes for broadcast/multicast address
                if (byte_count < 6) begin
                    if (byte_count == 0) begin
                        is_multicast <= rx_data[0];
                    end
                    
                    if (rx_data != 8'hFF) begin
                        is_broadcast <= 1'b0;
                    end
                    
                    byte_count <= byte_count + 1'b1;
                end
            end
            
            if (frame_end && frame_in_progress) begin
                total_frames <= total_frames + 1'b1;
                total_bytes <= total_bytes + current_frame_bytes;
                
                if (crc_error)
                    crc_error_frames <= crc_error_frames + 1'b1;
                    
                if (length_error)
                    length_error_frames <= length_error_frames + 1'b1;
                    
                if (is_broadcast)
                    broadcast_frames <= broadcast_frames + 1'b1;
                    
                if (is_multicast)
                    multicast_frames <= multicast_frames + 1'b1;
                    
                frame_in_progress <= 1'b0;
            end
        end
    end
endmodule