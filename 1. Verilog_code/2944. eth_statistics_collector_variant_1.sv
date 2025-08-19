//SystemVerilog
// SystemVerilog
//////////////////////////////////////////////////////////////////////////////
// Module: eth_statistics_collector
// Optimized pipeline architecture implementation
//////////////////////////////////////////////////////////////////////////////
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
    // Stage 1: Input capture and preprocessing
    reg [7:0] rx_data_stage1;
    reg rx_valid_stage1;
    reg frame_start_stage1;
    reg frame_end_stage1;
    reg crc_error_stage1;
    reg length_error_stage1;
    reg frame_in_progress;
    reg [2:0] byte_count;
    
    // Stage 2: Frame analysis
    reg [7:0] rx_data_stage2;
    reg rx_valid_stage2;
    reg frame_start_stage2;
    reg frame_end_stage2;
    reg crc_error_stage2;
    reg length_error_stage2;
    reg frame_in_progress_stage2;
    reg [2:0] byte_count_stage2;
    reg is_broadcast_stage2, is_multicast_stage2;
    reg [COUNTER_WIDTH-1:0] current_frame_bytes_stage2;
    
    // Stage 3: Counter update preparation
    reg frame_end_stage3;
    reg crc_error_stage3;
    reg length_error_stage3;
    reg is_broadcast_stage3, is_multicast_stage3;
    reg [COUNTER_WIDTH-1:0] current_frame_bytes_stage3;
    reg update_counters_stage3;
    
    // Pipeline Stage 1: Input capture and preprocessing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset stage 1 registers
            rx_data_stage1 <= 8'h0;
            rx_valid_stage1 <= 1'b0;
            frame_start_stage1 <= 1'b0;
            frame_end_stage1 <= 1'b0;
            crc_error_stage1 <= 1'b0;
            length_error_stage1 <= 1'b0;
            frame_in_progress <= 1'b0;
            byte_count <= 3'd0;
        end else begin
            // Capture inputs
            rx_data_stage1 <= rx_data;
            rx_valid_stage1 <= rx_valid;
            frame_start_stage1 <= frame_start;
            frame_end_stage1 <= frame_end;
            crc_error_stage1 <= crc_error;
            length_error_stage1 <= length_error;
            
            // Track frame state - optimized byte count logic
            if (frame_start) begin
                frame_in_progress <= 1'b1;
                byte_count <= 3'd0;
            end else if (frame_end) begin
                frame_in_progress <= 1'b0;
            end else if (rx_valid && frame_in_progress) begin
                // Only increment when below threshold (saves comparator)
                byte_count <= (byte_count < 3'd6) ? byte_count + 1'b1 : byte_count;
            end
        end
    end
    
    // Pipeline Stage 2: Frame analysis
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset stage 2 registers
            rx_data_stage2 <= 8'h0;
            rx_valid_stage2 <= 1'b0;
            frame_start_stage2 <= 1'b0;
            frame_end_stage2 <= 1'b0;
            crc_error_stage2 <= 1'b0;
            length_error_stage2 <= 1'b0;
            frame_in_progress_stage2 <= 1'b0;
            byte_count_stage2 <= 3'd0;
            is_broadcast_stage2 <= 1'b0;
            is_multicast_stage2 <= 1'b0;
            current_frame_bytes_stage2 <= {COUNTER_WIDTH{1'b0}};
        end else begin
            // Forward pipeline registers
            rx_data_stage2 <= rx_data_stage1;
            rx_valid_stage2 <= rx_valid_stage1;
            frame_start_stage2 <= frame_start_stage1;
            frame_end_stage2 <= frame_end_stage1;
            crc_error_stage2 <= crc_error_stage1;
            length_error_stage2 <= length_error_stage1;
            frame_in_progress_stage2 <= frame_in_progress;
            byte_count_stage2 <= byte_count;
            
            // Process frame data with optimized comparison logic
            if (frame_start_stage1) begin
                is_broadcast_stage2 <= 1'b1; // Assume broadcast until proven otherwise
                is_multicast_stage2 <= 1'b0;
                current_frame_bytes_stage2 <= {COUNTER_WIDTH{1'b0}};
            end else if (rx_valid_stage1 && frame_in_progress) begin
                // Increment byte counter for valid frame data
                current_frame_bytes_stage2 <= current_frame_bytes_stage2 + 1'b1;
                
                // Optimized multicast detection - only check first byte
                if (byte_count == 3'd0) begin
                    is_multicast_stage2 <= rx_data_stage1[0];
                end
                
                // Optimized broadcast detection - any non-FF byte in first 6 makes it non-broadcast
                if (byte_count < 3'd6) begin
                    // Only update when needed - prevent unnecessary toggling
                    is_broadcast_stage2 <= is_broadcast_stage2 & (rx_data_stage1 == 8'hFF);
                end
            end
        end
    end
    
    // Pipeline Stage 3: Counter update preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset stage 3 registers
            frame_end_stage3 <= 1'b0;
            crc_error_stage3 <= 1'b0;
            length_error_stage3 <= 1'b0;
            is_broadcast_stage3 <= 1'b0;
            is_multicast_stage3 <= 1'b0;
            current_frame_bytes_stage3 <= {COUNTER_WIDTH{1'b0}};
            update_counters_stage3 <= 1'b0;
        end else begin
            // Forward pipeline registers
            frame_end_stage3 <= frame_end_stage2;
            crc_error_stage3 <= crc_error_stage2;
            length_error_stage3 <= length_error_stage2;
            is_broadcast_stage3 <= is_broadcast_stage2;
            is_multicast_stage3 <= is_multicast_stage2;
            current_frame_bytes_stage3 <= current_frame_bytes_stage2;
            
            // Single comparison for update condition
            update_counters_stage3 <= frame_end_stage2 & frame_in_progress_stage2;
        end
    end
    
    // Final Stage: Counter Updates - optimized with parallel updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_bytes <= {COUNTER_WIDTH{1'b0}};
            total_frames <= {COUNTER_WIDTH{1'b0}};
            crc_error_frames <= {COUNTER_WIDTH{1'b0}};
            length_error_frames <= {COUNTER_WIDTH{1'b0}};
            broadcast_frames <= {COUNTER_WIDTH{1'b0}};
            multicast_frames <= {COUNTER_WIDTH{1'b0}};
        end else if (update_counters_stage3) begin
            // Combine all updates in a single clock cycle when counter update is needed
            total_frames <= total_frames + 1'b1;
            total_bytes <= total_bytes + current_frame_bytes_stage3;
            crc_error_frames <= crc_error_frames + crc_error_stage3;
            length_error_frames <= length_error_frames + length_error_stage3;
            broadcast_frames <= broadcast_frames + is_broadcast_stage3;
            multicast_frames <= multicast_frames + is_multicast_stage3;
        end
    end
endmodule