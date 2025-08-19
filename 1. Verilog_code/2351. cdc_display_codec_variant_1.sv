//SystemVerilog
module cdc_display_codec (
    input src_clk, dst_clk,
    input src_rst_n, dst_rst_n,
    input [23:0] pixel_data,
    input data_valid,
    output reg [15:0] display_data,
    output reg display_valid
);
    // Pre-compute RGB565 conversion as early as possible
    wire [15:0] encoded_data;
    assign encoded_data = {pixel_data[23:19], pixel_data[15:10], pixel_data[7:3]};
    
    // Source domain registers and wires
    reg valid_toggle_src;
    reg [1:0] handshake_src;
    reg [15:0] encoded_data_reg;
    
    // Destination domain registers
    reg valid_toggle_dst_meta, valid_toggle_dst;
    reg [1:0] handshake_dst_meta, handshake_dst;
    reg [15:0] sync_data;
    reg data_valid_edge;
    reg prev_handshake;
    
    // Source clock domain: Toggle valid bit and handle handshake
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            valid_toggle_src <= 1'b0;
            handshake_src <= 2'b00;
            encoded_data_reg <= 16'h0000;
        end else begin
            // Move data_valid detection out of the register update condition
            // to optimize timing by reducing input to register delay
            if (data_valid) begin
                encoded_data_reg <= encoded_data;
                valid_toggle_src <= ~valid_toggle_src;
            end
            
            // Handshake logic made more independent for better timing
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
            prev_handshake <= 1'b0;
            data_valid_edge <= 1'b0;
        end else begin
            // 2-stage synchronizer for control signals
            valid_toggle_dst_meta <= valid_toggle_src;
            valid_toggle_dst <= valid_toggle_dst_meta;
            
            // Handshake sync with forward retiming approach
            handshake_dst_meta <= {valid_toggle_dst, handshake_dst_meta[1]};
            handshake_dst <= handshake_dst_meta;
            
            // Detect toggle change using edge detection
            // This moves computational logic ahead of the register
            prev_handshake <= handshake_dst[1];
            data_valid_edge <= (handshake_dst[1] != prev_handshake);
            
            // Apply data and valid signals
            if (data_valid_edge) begin
                sync_data <= encoded_data_reg;
                display_valid <= 1'b1;
            end else begin
                display_valid <= 1'b0;
            end
            
            // Final output register stage
            display_data <= sync_data;
        end
    end
endmodule