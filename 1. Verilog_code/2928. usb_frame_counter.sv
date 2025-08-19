module usb_frame_counter(
    input wire clk,
    input wire rst_n,
    input wire sof_received,
    input wire frame_error,
    input wire [10:0] frame_number,
    output reg [10:0] expected_frame,
    output reg frame_missed,
    output reg frame_mismatch,
    output reg [15:0] sof_count,
    output reg [15:0] error_count,
    output wire [1:0] counter_status
);
    reg [15:0] consecutive_good;
    reg initialized;
    
    // Status output based on error counts
    assign counter_status = (error_count > 16'd10) ? 2'b11 :   // Critical errors
                           (error_count > 16'd0)  ? 2'b01 :   // Warning
                           2'b00;                             // Good
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            expected_frame <= 11'd0;
            frame_missed <= 1'b0;
            frame_mismatch <= 1'b0;
            sof_count <= 16'd0;
            error_count <= 16'd0;
            consecutive_good <= 16'd0;
            initialized <= 1'b0;
        end else begin
            // Clear single-cycle flags
            frame_missed <= 1'b0;
            frame_mismatch <= 1'b0;
            
            if (sof_received) begin
                sof_count <= sof_count + 16'd1;
                
                if (!initialized) begin
                    // First SOF received - initialize expected counter
                    expected_frame <= frame_number;
                    initialized <= 1'b1;
                    consecutive_good <= 16'd1;
                end else begin
                    // Check if received frame matches expected
                    if (frame_number != expected_frame) begin
                        frame_mismatch <= 1'b1;
                        error_count <= error_count + 16'd1;
                        consecutive_good <= 16'd0;
                    end else begin
                        consecutive_good <= consecutive_good + 16'd1;
                    end
                    
                    // Update expected frame for next SOF
                    expected_frame <= (frame_number + 11'd1) & 11'h7FF;
                end
            end else if (frame_error) begin
                error_count <= error_count + 16'd1;
                consecutive_good <= 16'd0;
            end
        end
    end
endmodule