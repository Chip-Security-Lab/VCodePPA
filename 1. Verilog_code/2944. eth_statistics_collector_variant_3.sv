//SystemVerilog
module eth_statistics_collector #(parameter COUNTER_WIDTH = 32) (
    input  wire                        clk,
    input  wire                        rst_n,
    input  wire                        rx_valid,
    input  wire [7:0]                  rx_data,
    input  wire                        frame_start,
    input  wire                        frame_end,
    input  wire                        crc_error,
    input  wire                        length_error,
    output reg  [COUNTER_WIDTH-1:0]    total_bytes,
    output reg  [COUNTER_WIDTH-1:0]    total_frames,
    output reg  [COUNTER_WIDTH-1:0]    crc_error_frames,
    output reg  [COUNTER_WIDTH-1:0]    length_error_frames,
    output reg  [COUNTER_WIDTH-1:0]    broadcast_frames,
    output reg  [COUNTER_WIDTH-1:0]    multicast_frames
);

    // =========================================================================
    // Frame tracking and byte counting pipeline stage
    // =========================================================================
    reg                       frame_in_progress;
    reg [COUNTER_WIDTH-1:0]   current_frame_bytes;
    reg [2:0]                 byte_count;
    
    // Destination address analysis pipeline registers
    reg                       is_broadcast_r1, is_broadcast_r2;
    reg                       is_multicast_r1, is_multicast_r2;
    
    // Frame status pipeline registers
    reg                       frame_end_r1;
    reg                       crc_error_r1;
    reg                       length_error_r1;
    reg [COUNTER_WIDTH-1:0]   frame_bytes_r1;
    
    // =========================================================================
    // Stage 1: Frame tracking and address analysis
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_in_progress <= 1'b0;
            current_frame_bytes <= {COUNTER_WIDTH{1'b0}};
            byte_count <= 3'd0;
            is_broadcast_r1 <= 1'b0;
            is_multicast_r1 <= 1'b0;
        end else begin
            // Frame start logic
            if (frame_start) begin
                frame_in_progress <= 1'b1;
                current_frame_bytes <= {COUNTER_WIDTH{1'b0}};
                byte_count <= 3'd0;
                is_broadcast_r1 <= 1'b1; // Assume broadcast until proven otherwise
                is_multicast_r1 <= 1'b0;
            end
            
            // Data reception and address analysis logic
            if (rx_valid && frame_in_progress) begin
                current_frame_bytes <= current_frame_bytes + 1'b1;
                
                // Check first 6 bytes for broadcast/multicast address
                if (byte_count < 6) begin
                    if (byte_count == 0) begin
                        is_multicast_r1 <= rx_data[0];
                    end
                    
                    if (rx_data != 8'hFF) begin
                        is_broadcast_r1 <= 1'b0;
                    end
                    
                    byte_count <= byte_count + 1'b1;
                end
            end
            
            // Frame end handling
            if (frame_end && frame_in_progress) begin
                frame_in_progress <= 1'b0;
            end
        end
    end

    // =========================================================================
    // Stage 2: Pipeline frame status information
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_end_r1 <= 1'b0;
            crc_error_r1 <= 1'b0;
            length_error_r1 <= 1'b0;
            frame_bytes_r1 <= {COUNTER_WIDTH{1'b0}};
            is_broadcast_r2 <= 1'b0;
            is_multicast_r2 <= 1'b0;
        end else begin
            // Pipeline frame status signals
            frame_end_r1 <= frame_end && frame_in_progress;
            crc_error_r1 <= crc_error;
            length_error_r1 <= length_error;
            
            // Pipeline frame data
            if (frame_end && frame_in_progress) begin
                frame_bytes_r1 <= current_frame_bytes;
                is_broadcast_r2 <= is_broadcast_r1;
                is_multicast_r2 <= is_multicast_r1;
            end
        end
    end

    // =========================================================================
    // Stage 3: Statistics counter update
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_bytes <= {COUNTER_WIDTH{1'b0}};
            total_frames <= {COUNTER_WIDTH{1'b0}};
            crc_error_frames <= {COUNTER_WIDTH{1'b0}};
            length_error_frames <= {COUNTER_WIDTH{1'b0}};
            broadcast_frames <= {COUNTER_WIDTH{1'b0}};
            multicast_frames <= {COUNTER_WIDTH{1'b0}};
        end else begin
            // Update counters based on pipelined frame completion
            if (frame_end_r1) begin
                total_frames <= total_frames + 1'b1;
                total_bytes <= total_bytes + frame_bytes_r1;
                
                if (crc_error_r1)
                    crc_error_frames <= crc_error_frames + 1'b1;
                    
                if (length_error_r1)
                    length_error_frames <= length_error_frames + 1'b1;
                    
                if (is_broadcast_r2)
                    broadcast_frames <= broadcast_frames + 1'b1;
                    
                if (is_multicast_r2)
                    multicast_frames <= multicast_frames + 1'b1;
            end
        end
    end

endmodule