module priority_display_codec (
    input clk, rst_n,
    input [23:0] rgb_data,
    input [7:0] mono_data,
    input [15:0] yuv_data,
    input [2:0] format_select, // 0:RGB, 1:MONO, 2:YUV, 3-7:Reserved
    input priority_override,  // High priority mode
    output reg [15:0] display_out,
    output reg format_valid
);
    reg [2:0] active_fmt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            display_out <= 16'h0000;
            format_valid <= 1'b0;
            active_fmt <= 3'b000;
        end else begin
            // Format selection logic with priority override
            active_fmt <= priority_override ? 3'b000 : format_select;
            
            case (active_fmt)
                3'b000: begin // RGB mode - convert RGB888 to RGB565
                    display_out <= {rgb_data[23:19], rgb_data[15:10], rgb_data[7:3]};
                    format_valid <= 1'b1;
                end
                3'b001: begin // Mono mode - replicate 8-bit mono to 16-bit grayscale
                    display_out <= {mono_data, mono_data};
                    format_valid <= 1'b1;
                end
                3'b010: begin // YUV mode - pass through 16-bit YUV
                    display_out <= yuv_data;
                    format_valid <= 1'b1;
                end
                default: begin // Invalid formats
                    display_out <= 16'h0000;
                    format_valid <= 1'b0;
                end
            endcase
        end
    end
endmodule