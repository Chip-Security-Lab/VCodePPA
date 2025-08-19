module adaptive_resolution_codec (
    input clk, rst_n,
    input [23:0] pixel_in,
    input [1:0] resolution_mode,  // 0: Full, 1: Half, 2: Quarter
    input data_valid, line_end, frame_end,
    output reg [15:0] pixel_out,
    output reg out_valid
);
    reg [1:0] x_cnt, y_cnt;
    reg [23:0] pixel_sum_r, pixel_sum_g, pixel_sum_b;
    reg [3:0] pixel_count;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt <= 2'd0;
            y_cnt <= 2'd0;
            pixel_sum_r <= 24'd0;
            pixel_sum_g <= 24'd0;
            pixel_sum_b <= 24'd0;
            pixel_count <= 4'd0;
            pixel_out <= 16'd0;
            out_valid <= 1'b0;
        end else begin
            out_valid <= 1'b0;
            
            if (frame_end) begin
                x_cnt <= 2'd0;
                y_cnt <= 2'd0;
            end else if (line_end) begin
                x_cnt <= 2'd0;
                y_cnt <= (y_cnt == 2'd3) ? 2'd0 : y_cnt + 2'd1;
            end
            
            if (data_valid) begin
                case (resolution_mode)
                    2'b00: begin // Full resolution
                        pixel_out <= {pixel_in[23:19], pixel_in[15:10], pixel_in[7:3]};
                        out_valid <= 1'b1;
                    end
                    2'b01: begin // Half resolution (2x2 averaging)
                        if (y_cnt[0] == 1'b0 && x_cnt[0] == 1'b0) begin
                            pixel_sum_r <= pixel_in[23:16];
                            pixel_sum_g <= pixel_in[15:8];
                            pixel_sum_b <= pixel_in[7:0];
                            pixel_count <= 4'd1;
                        end else begin
                            pixel_sum_r <= pixel_sum_r + pixel_in[23:16];
                            pixel_sum_g <= pixel_sum_g + pixel_in[15:8];
                            pixel_sum_b <= pixel_sum_b + pixel_in[7:0];
                            pixel_count <= pixel_count + 4'd1;
                            
                            if (pixel_count == 4'd3) begin
                                // Average and output
                                pixel_out <= {pixel_sum_r[9:5] + pixel_in[23:19], 
                                             pixel_sum_g[9:4] + pixel_in[15:10], 
                                             pixel_sum_b[9:5] + pixel_in[7:3]};
                                out_valid <= 1'b1;
                                pixel_count <= 4'd0;
                            end
                        end
                    end
                    2'b10: begin // Quarter resolution (4x4 averaging)
                        if (y_cnt == 2'd0 && x_cnt == 2'd0) begin
                            pixel_sum_r <= pixel_in[23:16];
                            pixel_sum_g <= pixel_in[15:8];
                            pixel_sum_b <= pixel_in[7:0];
                            pixel_count <= 4'd1;
                        end else begin
                            pixel_sum_r <= pixel_sum_r + pixel_in[23:16];
                            pixel_sum_g <= pixel_sum_g + pixel_in[15:8];
                            pixel_sum_b <= pixel_sum_b + pixel_in[7:0];
                            pixel_count <= pixel_count + 4'd1;
                            
                            if (pixel_count == 4'd15) begin
                                // Average and output
                                pixel_out <= {pixel_sum_r[11:7] + pixel_in[23:19], 
                                             pixel_sum_g[11:6] + pixel_in[15:10], 
                                             pixel_sum_b[11:7] + pixel_in[7:3]};
                                out_valid <= 1'b1;
                                pixel_count <= 4'd0;
                            end
                        end
                    end
                    default: begin
                        // Pass through
                        pixel_out <= {pixel_in[23:19], pixel_in[15:10], pixel_in[7:3]};
                        out_valid <= 1'b1;
                    end
                endcase
                
                x_cnt <= (x_cnt == 2'd3) ? 2'd0 : x_cnt + 2'd1;
            end
        end
    end
endmodule