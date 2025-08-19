//SystemVerilog
module multichannel_timer #(
    parameter CHANNELS = 4,
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire [CHANNELS-1:0] channel_en,
    input wire [DATA_WIDTH-1:0] timeout_values [CHANNELS-1:0],
    output reg [CHANNELS-1:0] timeout_flags,
    output reg [$clog2(CHANNELS)-1:0] active_channel
);
    // Main counter registers
    reg [DATA_WIDTH-1:0] counters [CHANNELS-1:0];
    
    // Buffer registers for high fanout signals
    reg [DATA_WIDTH-1:0] counters_buf1 [CHANNELS-1:0];
    reg [DATA_WIDTH-1:0] counters_buf2 [CHANNELS-1:0];
    reg [CHANNELS-1:0] channel_en_buf;
    reg [$clog2(CHANNELS)-1:0] channel_idx [2:0]; // Buffered loop index
    
    // Comparison result buffers
    reg [CHANNELS-1:0] timeout_cmp;
    
    integer i;
    
    // Buffer registers for timeout_values to reduce input load
    reg [DATA_WIDTH-1:0] timeout_values_buf [CHANNELS-1:0];
    
    // First stage: Buffer input signals and counters
    always @(posedge clock) begin
        channel_en_buf <= channel_en;
        
        for (i = 0; i < CHANNELS; i = i + 1) begin
            timeout_values_buf[i] <= timeout_values[i];
            counters_buf1[i] <= counters[i];
        end
    end
    
    // Second stage: Handle counter updates with distributed logic
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < CHANNELS; i = i + 1) begin
                counters[i] <= {DATA_WIDTH{1'b0}};
                timeout_flags <= {CHANNELS{1'b0}};
            end
            active_channel <= {$clog2(CHANNELS){1'b0}};
            
            // Reset buffered signals
            for (i = 0; i < CHANNELS; i = i + 1) begin
                counters_buf2[i] <= {DATA_WIDTH{1'b0}};
                timeout_cmp[i] <= 1'b0;
            end
            
            channel_idx[0] <= 0;
            channel_idx[1] <= 0;
            channel_idx[2] <= 0;
        end else begin
            // First group - case structure
            for (i = 0; i < CHANNELS/2; i = i + 1) begin
                timeout_cmp[i] <= (counters_buf1[i] >= timeout_values_buf[i]);
                
                case ({channel_en_buf[i], (counters_buf1[i] >= timeout_values_buf[i])})
                    2'b11: begin  // Enabled and timeout reached
                        counters[i] <= {DATA_WIDTH{1'b0}};
                        timeout_flags[i] <= 1'b1;
                        channel_idx[0] <= i;
                    end
                    2'b10: begin  // Enabled but timeout not reached
                        counters[i] <= counters_buf1[i] + 1'b1;
                        timeout_flags[i] <= 1'b0;
                    end
                    default: begin  // Not enabled
                        // Keep previous values
                    end
                endcase
            end
            
            // Second group - case structure
            for (i = CHANNELS/2; i < CHANNELS; i = i + 1) begin
                timeout_cmp[i] <= (counters_buf1[i] >= timeout_values_buf[i]);
                
                case ({channel_en_buf[i], (counters_buf1[i] >= timeout_values_buf[i])})
                    2'b11: begin  // Enabled and timeout reached
                        counters[i] <= {DATA_WIDTH{1'b0}};
                        timeout_flags[i] <= 1'b1;
                        channel_idx[1] <= i;
                    end
                    2'b10: begin  // Enabled but timeout not reached
                        counters[i] <= counters_buf1[i] + 1'b1;
                        timeout_flags[i] <= 1'b0;
                    end
                    default: begin  // Not enabled
                        // Keep previous values
                    end
                endcase
            end
            
            // Buffer second stage of channel index selection
            for (i = 0; i < CHANNELS; i = i + 1) begin
                counters_buf2[i] <= counters[i];
            end
            
            // Channel selection logic with case statement
            case ({timeout_cmp[channel_idx[0]], timeout_cmp[channel_idx[1]]})
                2'b10, 2'b11: begin  // First channel has timeout
                    channel_idx[2] <= channel_idx[0];
                end
                2'b01: begin  // Only second channel has timeout
                    channel_idx[2] <= channel_idx[1];
                end
                default: begin  // No timeouts
                    channel_idx[2] <= active_channel;
                end
            endcase
            
            active_channel <= channel_idx[2];
        end
    end
endmodule