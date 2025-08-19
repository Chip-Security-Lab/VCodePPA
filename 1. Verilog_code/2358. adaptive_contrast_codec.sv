module adaptive_contrast_codec (
    input clk, rst_n,
    input [7:0] pixel_in,
    input [7:0] min_val, max_val,  // Current frame min/max values
    input enable, new_frame,
    output reg [7:0] pixel_out
);
    reg [7:0] contrast_min, contrast_max;
    wire [8:0] range = contrast_max - contrast_min;
    wire [16:0] scaled_pixel = ((pixel_in - contrast_min) * 255) / (range == 0 ? 8'd1 : range);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            contrast_min <= 8'd0;
            contrast_max <= 8'd255;
            pixel_out <= 8'd0;
        end else begin
            // Update contrast range on new frame
            if (new_frame) begin
                contrast_min <= min_val;
                contrast_max <= max_val;
            end
            
            // Apply contrast stretching if enabled
            if (enable)
                pixel_out <= (scaled_pixel > 255) ? 8'd255 : scaled_pixel[7:0];
            else
                pixel_out <= pixel_in;
        end
    end
endmodule