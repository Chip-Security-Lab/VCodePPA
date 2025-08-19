//SystemVerilog

//------------------------------------------------------------------------------
// Top-level module
//------------------------------------------------------------------------------
module eth_statistics_collector #(parameter COUNTER_WIDTH = 32) (
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire                       rx_valid,
    input  wire [7:0]                 rx_data,
    input  wire                       frame_start,
    input  wire                       frame_end,
    input  wire                       crc_error,
    input  wire                       length_error,
    output wire [COUNTER_WIDTH-1:0]   total_bytes,
    output wire [COUNTER_WIDTH-1:0]   total_frames,
    output wire [COUNTER_WIDTH-1:0]   crc_error_frames,
    output wire [COUNTER_WIDTH-1:0]   length_error_frames,
    output wire [COUNTER_WIDTH-1:0]   broadcast_frames,
    output wire [COUNTER_WIDTH-1:0]   multicast_frames
);
    // Internal signals
    wire                      frame_in_progress;
    wire [COUNTER_WIDTH-1:0]  current_frame_bytes;
    wire                      is_broadcast;
    wire                      is_multicast;
    
    // Frame tracker module instance
    frame_tracker #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) u_frame_tracker (
        .clk                (clk),
        .rst_n              (rst_n),
        .rx_valid           (rx_valid),
        .frame_start        (frame_start),
        .frame_end          (frame_end),
        .frame_in_progress  (frame_in_progress),
        .current_frame_bytes(current_frame_bytes)
    );
    
    // Address classifier module instance
    address_classifier u_address_classifier (
        .clk                (clk),
        .rst_n              (rst_n),
        .rx_valid           (rx_valid),
        .rx_data            (rx_data),
        .frame_start        (frame_start),
        .frame_in_progress  (frame_in_progress),
        .is_broadcast       (is_broadcast),
        .is_multicast       (is_multicast)
    );
    
    // Counters module instance
    statistics_counters #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) u_statistics_counters (
        .clk                (clk),
        .rst_n              (rst_n),
        .frame_end          (frame_end),
        .frame_in_progress  (frame_in_progress),
        .current_frame_bytes(current_frame_bytes),
        .is_broadcast       (is_broadcast),
        .is_multicast       (is_multicast),
        .crc_error          (crc_error),
        .length_error       (length_error),
        .total_bytes        (total_bytes),
        .total_frames       (total_frames),
        .crc_error_frames   (crc_error_frames),
        .length_error_frames(length_error_frames),
        .broadcast_frames   (broadcast_frames),
        .multicast_frames   (multicast_frames)
    );
    
endmodule

//------------------------------------------------------------------------------
// Frame tracking sub-module
//------------------------------------------------------------------------------
module frame_tracker #(parameter COUNTER_WIDTH = 32) (
    input  wire                        clk,
    input  wire                        rst_n,
    input  wire                        rx_valid,
    input  wire                        frame_start,
    input  wire                        frame_end,
    output reg                         frame_in_progress,
    output reg  [COUNTER_WIDTH-1:0]    current_frame_bytes
);
    
    // Frame tracking and byte counting logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_in_progress <= 1'b0;
            current_frame_bytes <= {COUNTER_WIDTH{1'b0}};
        end else begin
            if (frame_start) begin
                frame_in_progress <= 1'b1;
                current_frame_bytes <= {COUNTER_WIDTH{1'b0}};
            end else if (rx_valid && frame_in_progress) begin
                current_frame_bytes <= current_frame_bytes + 1'b1;
            end else if (frame_end && frame_in_progress) begin
                frame_in_progress <= 1'b0;
            end
        end
    end
    
endmodule

//------------------------------------------------------------------------------
// Address classification sub-module
//------------------------------------------------------------------------------
module address_classifier (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx_valid,
    input  wire [7:0] rx_data,
    input  wire       frame_start,
    input  wire       frame_in_progress,
    output reg        is_broadcast,
    output reg        is_multicast
);
    reg [2:0] byte_count;
    
    // Byte counter for MAC address tracking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_count <= 3'd0;
        end else begin
            if (frame_start) begin
                byte_count <= 3'd0;
            end else if (rx_valid && frame_in_progress && (byte_count < 6)) begin
                byte_count <= byte_count + 1'b1;
            end
        end
    end
    
    // Broadcast/multicast detection logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_broadcast <= 1'b0;
            is_multicast <= 1'b0;
        end else begin
            if (frame_start) begin
                is_broadcast <= 1'b1; // Assume broadcast until proven otherwise
                is_multicast <= 1'b0;
            end else if (rx_valid && frame_in_progress && (byte_count < 6)) begin
                if (byte_count == 0) begin
                    is_multicast <= rx_data[0];
                end
                
                if (rx_data != 8'hFF) begin
                    is_broadcast <= 1'b0;
                end
            end
        end
    end
    
endmodule

//------------------------------------------------------------------------------
// Statistics counters sub-module
//------------------------------------------------------------------------------
module statistics_counters #(parameter COUNTER_WIDTH = 32) (
    input  wire                        clk,
    input  wire                        rst_n,
    input  wire                        frame_end,
    input  wire                        frame_in_progress,
    input  wire [COUNTER_WIDTH-1:0]    current_frame_bytes,
    input  wire                        is_broadcast,
    input  wire                        is_multicast,
    input  wire                        crc_error,
    input  wire                        length_error,
    output reg  [COUNTER_WIDTH-1:0]    total_bytes,
    output reg  [COUNTER_WIDTH-1:0]    total_frames,
    output reg  [COUNTER_WIDTH-1:0]    crc_error_frames,
    output reg  [COUNTER_WIDTH-1:0]    length_error_frames,
    output reg  [COUNTER_WIDTH-1:0]    broadcast_frames,
    output reg  [COUNTER_WIDTH-1:0]    multicast_frames
);

    // Basic frame statistics counters
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_bytes <= {COUNTER_WIDTH{1'b0}};
            total_frames <= {COUNTER_WIDTH{1'b0}};
        end else if (frame_end && frame_in_progress) begin
            total_frames <= total_frames + 1'b1;
            total_bytes <= total_bytes + current_frame_bytes;
        end
    end
    
    // Error frames counters
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_error_frames <= {COUNTER_WIDTH{1'b0}};
            length_error_frames <= {COUNTER_WIDTH{1'b0}};
        end else if (frame_end && frame_in_progress) begin
            if (crc_error)
                crc_error_frames <= crc_error_frames + 1'b1;
                
            if (length_error)
                length_error_frames <= length_error_frames + 1'b1;
        end
    end
    
    // Broadcast/multicast frames counters
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            broadcast_frames <= {COUNTER_WIDTH{1'b0}};
            multicast_frames <= {COUNTER_WIDTH{1'b0}};
        end else if (frame_end && frame_in_progress) begin
            if (is_broadcast)
                broadcast_frames <= broadcast_frames + 1'b1;
                
            if (is_multicast)
                multicast_frames <= multicast_frames + 1'b1;
        end
    end

endmodule