//SystemVerilog
module cdc_display_codec (
    input src_clk, dst_clk,
    input src_rst_n, dst_rst_n,
    input [23:0] pixel_data,
    input data_valid,
    output reg [15:0] display_data,
    output reg display_valid
);
    // Source domain pipeline registers
    reg [23:0] pixel_data_stage1;
    reg data_valid_stage1;
    reg [7:0] red_stage2, green_stage2, blue_stage2;
    reg data_valid_stage2;
    reg [4:0] red_encoded_stage3, green_encoded_stage3, blue_encoded_stage3;
    reg data_valid_stage3;
    reg [15:0] encoded_data_stage4;
    reg valid_toggle_src;
    reg [1:0] handshake_src;
    
    // Destination domain registers
    reg valid_toggle_dst_meta1, valid_toggle_dst_meta2;
    reg valid_toggle_dst;
    reg [1:0] handshake_dst_meta1, handshake_dst_meta2, handshake_dst;
    reg handshake_change_detected_stage1;
    reg [15:0] sync_data_stage1;
    reg display_valid_stage1;
    reg [15:0] sync_data_stage2;
    reg display_valid_stage2;
    
    // Source clock domain: Multi-stage pipeline
    // Stage 1: Register input data
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            pixel_data_stage1 <= 24'h000000;
            data_valid_stage1 <= 1'b0;
        end else begin
            pixel_data_stage1 <= pixel_data;
            data_valid_stage1 <= data_valid;
        end
    end
    
    // Stage 2: Separate color components
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            red_stage2 <= 8'h00;
            green_stage2 <= 8'h00;
            blue_stage2 <= 8'h00;
            data_valid_stage2 <= 1'b0;
        end else begin
            red_stage2 <= pixel_data_stage1[23:16];
            green_stage2 <= pixel_data_stage1[15:8];
            blue_stage2 <= pixel_data_stage1[7:0];
            data_valid_stage2 <= data_valid_stage1;
        end
    end
    
    // Stage 3: Perform color reduction
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            red_encoded_stage3 <= 5'h00;
            green_encoded_stage3 <= 6'h00;
            blue_encoded_stage3 <= 5'h00;
            data_valid_stage3 <= 1'b0;
        end else begin
            red_encoded_stage3 <= red_stage2[7:3];
            green_encoded_stage3 <= green_stage2[7:2];
            blue_encoded_stage3 <= blue_stage2[7:3];
            data_valid_stage3 <= data_valid_stage2;
        end
    end
    
    // Stage 4: Combine encoded data and toggle valid bit
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            encoded_data_stage4 <= 16'h0000;
            valid_toggle_src <= 1'b0;
            handshake_src <= 2'b00;
        end else begin
            if (data_valid_stage3) begin
                // RGB565 format
                encoded_data_stage4 <= {red_encoded_stage3, green_encoded_stage3, blue_encoded_stage3};
                valid_toggle_src <= ~valid_toggle_src;
            end
            
            // Handshake sync
            handshake_src <= {handshake_dst_meta2, handshake_src[1]};
        end
    end
    
    // Destination clock domain: Enhanced synchronizer pipeline
    // Stage 1: First-level synchronization
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            valid_toggle_dst_meta1 <= 1'b0;
            handshake_dst_meta1 <= 2'b00;
        end else begin
            valid_toggle_dst_meta1 <= valid_toggle_src;
            handshake_dst_meta1 <= {valid_toggle_dst, handshake_dst_meta1[1]};
        end
    end
    
    // Stage 2: Second-level synchronization
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            valid_toggle_dst_meta2 <= 1'b0;
            valid_toggle_dst <= 1'b0;
            handshake_dst_meta2 <= 2'b00;
            handshake_dst <= 2'b00;
        end else begin
            valid_toggle_dst_meta2 <= valid_toggle_dst_meta1;
            valid_toggle_dst <= valid_toggle_dst_meta2;
            handshake_dst_meta2 <= handshake_dst_meta1;
            handshake_dst <= handshake_dst_meta2;
        end
    end
    
    // Stage 3: Detect handshake change and capture data
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            handshake_change_detected_stage1 <= 1'b0;
            sync_data_stage1 <= 16'h0000;
            display_valid_stage1 <= 1'b0;
        end else begin
            handshake_change_detected_stage1 <= (handshake_dst[1] != handshake_dst[0]);
            
            if (handshake_dst[1] != handshake_dst[0]) begin
                sync_data_stage1 <= encoded_data_stage4;
                display_valid_stage1 <= 1'b1;
            end else begin
                display_valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 4: Final output stage
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            sync_data_stage2 <= 16'h0000;
            display_valid_stage2 <= 1'b0;
            display_data <= 16'h0000;
            display_valid <= 1'b0;
        end else begin
            sync_data_stage2 <= sync_data_stage1;
            display_valid_stage2 <= display_valid_stage1;
            display_data <= sync_data_stage2;
            display_valid <= display_valid_stage2;
        end
    end
endmodule