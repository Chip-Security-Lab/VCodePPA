//SystemVerilog
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
    // Pipeline Stage 1: Input Registration
    reg rx_valid_stage1;
    reg [7:0] rx_data_stage1;
    reg frame_start_stage1, frame_end_stage1;
    reg crc_error_stage1, length_error_stage1;
    
    // Pipeline Stage 2: Frame Processing
    reg frame_in_progress_stage2;
    reg [COUNTER_WIDTH-1:0] current_frame_bytes_stage2;
    reg is_broadcast_stage2, is_multicast_stage2;
    reg [2:0] byte_count_stage2;
    reg frame_end_stage2, crc_error_stage2, length_error_stage2;
    
    // Pipeline Stage 3: Counter Calculation
    reg [COUNTER_WIDTH-1:0] total_bytes_stage3;
    reg [COUNTER_WIDTH-1:0] total_frames_stage3;
    reg [COUNTER_WIDTH-1:0] crc_error_frames_stage3;
    reg [COUNTER_WIDTH-1:0] length_error_frames_stage3;
    reg [COUNTER_WIDTH-1:0] broadcast_frames_stage3;
    reg [COUNTER_WIDTH-1:0] multicast_frames_stage3;
    
    // Valid signals for pipeline control
    reg valid_stage2, valid_stage3;
    
    // Pipeline flow control
    reg process_frame_stage2;
    reg update_counters_stage2;
    
    // ---------------------------
    // Pipeline Stage 1: Input Registration
    // ---------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid_stage1 <= 1'b0;
            rx_data_stage1 <= 8'h0;
            frame_start_stage1 <= 1'b0;
            frame_end_stage1 <= 1'b0;
            crc_error_stage1 <= 1'b0;
            length_error_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            rx_valid_stage1 <= rx_valid;
            rx_data_stage1 <= rx_data;
            frame_start_stage1 <= frame_start;
            frame_end_stage1 <= frame_end;
            crc_error_stage1 <= crc_error;
            length_error_stage1 <= length_error;
            valid_stage2 <= 1'b1; // Always forward valid signal to next stage
        end
    end
    
    // ---------------------------
    // Pipeline Stage 2: Frame Processing
    // ---------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_in_progress_stage2 <= 1'b0;
            current_frame_bytes_stage2 <= {COUNTER_WIDTH{1'b0}};
            is_broadcast_stage2 <= 1'b0;
            is_multicast_stage2 <= 1'b0;
            byte_count_stage2 <= 3'd0;
            frame_end_stage2 <= 1'b0;
            crc_error_stage2 <= 1'b0;
            length_error_stage2 <= 1'b0;
            process_frame_stage2 <= 1'b0;
            update_counters_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            // Default values
            process_frame_stage2 <= 1'b0;
            update_counters_stage2 <= 1'b0;
            frame_end_stage2 <= frame_end_stage1;
            crc_error_stage2 <= crc_error_stage1;
            length_error_stage2 <= length_error_stage1;
            valid_stage3 <= 1'b1;
            
            if (frame_start_stage1) begin
                frame_in_progress_stage2 <= 1'b1;
                current_frame_bytes_stage2 <= {COUNTER_WIDTH{1'b0}};
                is_broadcast_stage2 <= 1'b1; // Assume broadcast until proven otherwise
                is_multicast_stage2 <= 1'b0;
                byte_count_stage2 <= 3'd0;
                process_frame_stage2 <= 1'b1;
            end else if (rx_valid_stage1 && frame_in_progress_stage2) begin
                process_frame_stage2 <= 1'b1;
                current_frame_bytes_stage2 <= current_frame_bytes_stage2 + 1'b1;
                
                // Check first 6 bytes for broadcast/multicast address
                if (byte_count_stage2 < 6) begin
                    if (byte_count_stage2 == 0) begin
                        is_multicast_stage2 <= rx_data_stage1[0];
                    end
                    
                    if (rx_data_stage1 != 8'hFF) begin
                        is_broadcast_stage2 <= 1'b0;
                    end
                    
                    byte_count_stage2 <= byte_count_stage2 + 1'b1;
                end
            end
            
            if (frame_end_stage1 && frame_in_progress_stage2) begin
                update_counters_stage2 <= 1'b1;
                frame_in_progress_stage2 <= 1'b0;
            end
        end
    end
    
    // ---------------------------
    // Pipeline Stage 3: Counter Calculation
    // ---------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_bytes_stage3 <= {COUNTER_WIDTH{1'b0}};
            total_frames_stage3 <= {COUNTER_WIDTH{1'b0}};
            crc_error_frames_stage3 <= {COUNTER_WIDTH{1'b0}};
            length_error_frames_stage3 <= {COUNTER_WIDTH{1'b0}};
            broadcast_frames_stage3 <= {COUNTER_WIDTH{1'b0}};
            multicast_frames_stage3 <= {COUNTER_WIDTH{1'b0}};
        end else if (valid_stage3) begin
            // Default assignments
            total_bytes_stage3 <= total_bytes_stage3;
            total_frames_stage3 <= total_frames_stage3;
            crc_error_frames_stage3 <= crc_error_frames_stage3;
            length_error_frames_stage3 <= length_error_frames_stage3;
            broadcast_frames_stage3 <= broadcast_frames_stage3;
            multicast_frames_stage3 <= multicast_frames_stage3;
            
            if (update_counters_stage2) begin
                total_frames_stage3 <= total_frames_stage3 + 1'b1;
                total_bytes_stage3 <= total_bytes_stage3 + current_frame_bytes_stage2;
                
                if (crc_error_stage2)
                    crc_error_frames_stage3 <= crc_error_frames_stage3 + 1'b1;
                
                if (length_error_stage2)
                    length_error_frames_stage3 <= length_error_frames_stage3 + 1'b1;
                
                if (is_broadcast_stage2)
                    broadcast_frames_stage3 <= broadcast_frames_stage3 + 1'b1;
                
                if (is_multicast_stage2)
                    multicast_frames_stage3 <= multicast_frames_stage3 + 1'b1;
            end
        end
    end
    
    // Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_bytes <= {COUNTER_WIDTH{1'b0}};
            total_frames <= {COUNTER_WIDTH{1'b0}};
            crc_error_frames <= {COUNTER_WIDTH{1'b0}};
            length_error_frames <= {COUNTER_WIDTH{1'b0}};
            broadcast_frames <= {COUNTER_WIDTH{1'b0}};
            multicast_frames <= {COUNTER_WIDTH{1'b0}};
        end else begin
            total_bytes <= total_bytes_stage3;
            total_frames <= total_frames_stage3;
            crc_error_frames <= crc_error_frames_stage3;
            length_error_frames <= length_error_frames_stage3;
            broadcast_frames <= broadcast_frames_stage3;
            multicast_frames <= multicast_frames_stage3;
        end
    end
endmodule