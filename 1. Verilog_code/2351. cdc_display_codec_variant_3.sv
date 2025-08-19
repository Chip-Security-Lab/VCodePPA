//SystemVerilog
module cdc_display_codec (
    input src_clk, dst_clk,
    input src_rst_n, dst_rst_n,
    input [23:0] pixel_data,
    input data_valid,
    output reg [15:0] display_data,
    output reg display_valid
);
    // Source domain registers
    reg [15:0] encoded_data;
    reg valid_toggle_src;
    reg [1:0] handshake_src;
    
    // Destination domain registers
    reg [15:0] sync_data;
    reg valid_toggle_dst_meta, valid_toggle_dst;
    reg [1:0] handshake_dst_meta, handshake_dst;
    
    // Optimized RGB888 to RGB565 conversion with direct bit extraction
    // Using bit concatenation for better synthesis results
    wire [15:0] rgb565_data = {pixel_data[23:19], pixel_data[15:10], pixel_data[7:3]};
    
    // Source clock domain logic with improved reset handling
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            encoded_data <= 16'h0000;
            valid_toggle_src <= 1'b0;
            handshake_src <= 2'b00;
        end else begin
            // Efficient handshake synchronization
            handshake_src <= {handshake_dst_meta, handshake_src[1]};
            
            // Data encoding with conditional assignment
            if (data_valid) begin
                encoded_data <= rgb565_data;
                valid_toggle_src <= ~valid_toggle_src;
            end
        end
    end
    
    // Optimized edge detection using XOR for better timing
    wire handshake_edge = handshake_dst[1] ^ handshake_dst[0];
    
    // Destination clock domain with improved synchronization
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            // Group related signals for better reset structure
            {valid_toggle_dst_meta, valid_toggle_dst} <= 2'b00;
            {handshake_dst_meta, handshake_dst} <= 4'b0000;
            sync_data <= 16'h0000;
            display_data <= 16'h0000;
            display_valid <= 1'b0;
        end else begin
            // 2-stage synchronizer with pipelined structure
            valid_toggle_dst_meta <= valid_toggle_src;
            valid_toggle_dst <= valid_toggle_dst_meta;
            
            // Improved handshake synchronization
            handshake_dst_meta <= {valid_toggle_dst, handshake_dst_meta[1]};
            handshake_dst <= handshake_dst_meta;
            
            // Data path with reduced logic dependency
            display_valid <= handshake_edge;
            
            // Conditional data update to prevent glitches
            if (handshake_edge) begin
                sync_data <= encoded_data;
            end
            
            // Final output register for improved timing isolation
            display_data <= sync_data;
        end
    end
endmodule