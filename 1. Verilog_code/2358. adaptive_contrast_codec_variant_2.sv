//SystemVerilog
module adaptive_contrast_codec (
    input clk, rst_n,
    input [7:0] pixel_in,
    input [7:0] min_val, max_val,  // Current frame min/max values
    input enable, new_frame,
    output reg [7:0] pixel_out
);
    // Pipeline registers
    reg [7:0] contrast_min, contrast_max;
    reg [7:0] pixel_in_reg;
    reg enable_reg;
    
    // Pre-calculate subtraction term to reduce critical path
    wire [7:0] pixel_offset = pixel_in_reg - contrast_min;
    
    // Calculate range with protection against division by zero
    wire [7:0] range = (contrast_max > contrast_min) ? (contrast_max - contrast_min) : 8'd1;
    
    // Scale pixel value - split multiplication and division into separate stages
    wire [15:0] scaled_value = pixel_offset * 8'd255;
    wire [7:0] final_pixel = (scaled_value / range > 8'd255) ? 8'd255 : scaled_value / range;
    
    // Input registration - separate always block for input pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_in_reg <= 8'd0;
            enable_reg <= 1'b0;
        end else begin
            pixel_in_reg <= pixel_in;
            enable_reg <= enable;
        end
    end
    
    // Contrast parameters update - separate always block for min/max values
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            contrast_min <= 8'd0;
            contrast_max <= 8'd255;
        end else if (new_frame) begin
            contrast_min <= min_val;
            contrast_max <= max_val;
        end
    end
    
    // Output generation - separate always block for final pixel output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_out <= 8'd0;
        end else begin
            pixel_out <= enable_reg ? final_pixel : pixel_in_reg;
        end
    end
endmodule