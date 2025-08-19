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
    
    // Source clock domain: Encode and toggle valid bit
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            encoded_data <= 16'h0000;
            valid_toggle_src <= 1'b0;
            handshake_src <= 2'b00;
        end else begin
            if (data_valid) begin
                // RGB888 to RGB565 conversion
                encoded_data <= {pixel_data[23:19], pixel_data[15:10], pixel_data[7:3]};
                valid_toggle_src <= ~valid_toggle_src;
            end
            
            // Handshake sync
            handshake_src <= {handshake_dst_meta, handshake_src[1]};
        end
    end
    
    // Destination clock domain: Synchronize and output
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            valid_toggle_dst_meta <= 1'b0;
            valid_toggle_dst <= 1'b0;
            handshake_dst_meta <= 2'b00;
            handshake_dst <= 2'b00;
            sync_data <= 16'h0000;
            display_data <= 16'h0000;
            display_valid <= 1'b0;
        end else begin
            // 2-stage synchronizer for control signals
            valid_toggle_dst_meta <= valid_toggle_src;
            valid_toggle_dst <= valid_toggle_dst_meta;
            
            // Handshake sync
            handshake_dst_meta <= {valid_toggle_dst, handshake_dst_meta[1]};
            handshake_dst <= handshake_dst_meta;
            
            // Detect toggle change to update output
            if (handshake_dst[1] != handshake_dst[0]) begin
                sync_data <= encoded_data;
                display_valid <= 1'b1;
            end else begin
                display_valid <= 1'b0;
            end
            
            display_data <= sync_data;
        end
    end
endmodule