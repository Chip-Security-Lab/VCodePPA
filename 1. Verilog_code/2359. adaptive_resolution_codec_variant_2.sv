//SystemVerilog
module adaptive_resolution_codec (
    input wire clk, rst_n,
    
    // AXI-Stream Slave Interface
    input wire [23:0] s_axis_tdata,
    input wire [2:0] s_axis_tuser,  // {resolution_mode[1:0], line_end}
    input wire s_axis_tlast,        // frame_end
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // AXI-Stream Master Interface
    output wire [15:0] m_axis_tdata,
    output wire m_axis_tlast,
    output wire m_axis_tvalid,
    input wire m_axis_tready
);

    // Internal signals - Stage 1: Input capture and mode determination
    reg [1:0] x_cnt_stage1, y_cnt_stage1;
    reg [23:0] pixel_data_stage1;
    reg [1:0] resolution_mode_stage1;
    reg line_end_stage1, frame_end_stage1;
    reg data_valid_stage1;
    reg [3:0] pixel_count_stage1;
    
    // Stage 2: Pixel accumulation
    reg [1:0] x_cnt_stage2, y_cnt_stage2;
    reg [23:0] pixel_data_stage2;
    reg [1:0] resolution_mode_stage2;
    reg line_end_stage2, frame_end_stage2;
    reg data_valid_stage2;
    reg [3:0] pixel_count_stage2;
    reg [23:0] pixel_sum_r_stage2, pixel_sum_g_stage2, pixel_sum_b_stage2;
    reg accumulation_complete_stage2;
    
    // Stage 3: Averaging calculation
    reg [23:0] pixel_sum_r_stage3, pixel_sum_g_stage3, pixel_sum_b_stage3;
    reg [23:0] pixel_data_stage3;
    reg [1:0] resolution_mode_stage3;
    reg frame_end_stage3;
    reg data_valid_stage3;
    reg [3:0] pixel_count_stage3;
    reg accumulation_complete_stage3;
    
    // Stage 4: Output formatting
    reg [15:0] pixel_out_reg_stage4;
    reg out_valid_reg_stage4;
    reg frame_end_reg_stage4;
    
    // Extract signals from AXI-Stream
    wire [1:0] resolution_mode = s_axis_tuser[2:1];
    wire line_end = s_axis_tuser[0];
    wire frame_end = s_axis_tlast;
    wire data_valid = s_axis_tvalid && s_axis_tready;
    
    // AXI-Stream handshaking control
    assign s_axis_tready = !out_valid_reg_stage4 || m_axis_tready;
    
    // AXI-Stream master interface assignments
    assign m_axis_tdata = pixel_out_reg_stage4;
    assign m_axis_tvalid = out_valid_reg_stage4;
    assign m_axis_tlast = frame_end_reg_stage4;
    
    // Stage 1: Input capture and mode determination
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt_stage1 <= 2'd0;
            y_cnt_stage1 <= 2'd0;
            pixel_data_stage1 <= 24'd0;
            resolution_mode_stage1 <= 2'd0;
            line_end_stage1 <= 1'b0;
            frame_end_stage1 <= 1'b0;
            data_valid_stage1 <= 1'b0;
            pixel_count_stage1 <= 4'd0;
        end else begin
            data_valid_stage1 <= data_valid;
            
            if (data_valid) begin
                pixel_data_stage1 <= s_axis_tdata;
                resolution_mode_stage1 <= resolution_mode;
                line_end_stage1 <= line_end;
                frame_end_stage1 <= frame_end;
                
                if (frame_end) begin
                    x_cnt_stage1 <= 2'd0;
                    y_cnt_stage1 <= 2'd0;
                    pixel_count_stage1 <= 4'd0;
                end else if (line_end) begin
                    x_cnt_stage1 <= 2'd0;
                    y_cnt_stage1 <= (y_cnt_stage1 == 2'd3) ? 2'd0 : y_cnt_stage1 + 2'd1;
                    
                    // Reset pixel count at end of line based on resolution mode
                    if (resolution_mode == 2'b01 && y_cnt_stage1[0] == 1'b1) begin
                        pixel_count_stage1 <= 4'd0;
                    end else if (resolution_mode == 2'b10 && y_cnt_stage1 == 2'd3) begin
                        pixel_count_stage1 <= 4'd0;
                    end else begin
                        pixel_count_stage1 <= pixel_count_stage1;
                    end
                end else begin
                    x_cnt_stage1 <= (x_cnt_stage1 == 2'd3) ? 2'd0 : x_cnt_stage1 + 2'd1;
                    
                    // Update pixel count based on resolution mode
                    case (resolution_mode)
                        2'b00: pixel_count_stage1 <= 4'd0; // Full resolution
                        2'b01: begin // Half resolution (2x2)
                            if (x_cnt_stage1 == 2'd1 && y_cnt_stage1[0] == 1'b1) begin
                                pixel_count_stage1 <= 4'd0;
                            end else begin
                                pixel_count_stage1 <= pixel_count_stage1 + 4'd1;
                            end
                        end
                        2'b10: begin // Quarter resolution (4x4)
                            if (x_cnt_stage1 == 2'd3 && y_cnt_stage1 == 2'd3) begin
                                pixel_count_stage1 <= 4'd0;
                            end else begin
                                pixel_count_stage1 <= pixel_count_stage1 + 4'd1;
                            end
                        end
                        default: pixel_count_stage1 <= 4'd0;
                    endcase
                end
            end
        end
    end

    // Stage 2: Pixel accumulation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt_stage2 <= 2'd0;
            y_cnt_stage2 <= 2'd0;
            pixel_data_stage2 <= 24'd0;
            resolution_mode_stage2 <= 2'd0;
            line_end_stage2 <= 1'b0;
            frame_end_stage2 <= 1'b0;
            data_valid_stage2 <= 1'b0;
            pixel_count_stage2 <= 4'd0;
            pixel_sum_r_stage2 <= 24'd0;
            pixel_sum_g_stage2 <= 24'd0;
            pixel_sum_b_stage2 <= 24'd0;
            accumulation_complete_stage2 <= 1'b0;
        end else begin
            pixel_data_stage2 <= pixel_data_stage1;
            resolution_mode_stage2 <= resolution_mode_stage1;
            line_end_stage2 <= line_end_stage1;
            frame_end_stage2 <= frame_end_stage1;
            data_valid_stage2 <= data_valid_stage1;
            x_cnt_stage2 <= x_cnt_stage1;
            y_cnt_stage2 <= y_cnt_stage1;
            pixel_count_stage2 <= pixel_count_stage1;
            
            accumulation_complete_stage2 <= 1'b0;
            
            if (data_valid_stage1) begin
                case (resolution_mode_stage1)
                    2'b00: begin // Full resolution
                        // No accumulation needed
                        pixel_sum_r_stage2 <= {pixel_data_stage1[23:16], 16'b0};
                        pixel_sum_g_stage2 <= {pixel_data_stage1[15:8], 16'b0};
                        pixel_sum_b_stage2 <= {pixel_data_stage1[7:0], 16'b0};
                        accumulation_complete_stage2 <= 1'b1;
                    end
                    2'b01: begin // Half resolution (2x2 averaging)
                        if (y_cnt_stage1[0] == 1'b0 && x_cnt_stage1[0] == 1'b0) begin
                            // First pixel in 2x2 block
                            pixel_sum_r_stage2 <= {8'b0, pixel_data_stage1[23:16], 8'b0};
                            pixel_sum_g_stage2 <= {8'b0, pixel_data_stage1[15:8], 8'b0};
                            pixel_sum_b_stage2 <= {8'b0, pixel_data_stage1[7:0], 8'b0};
                        end else begin
                            // Accumulate
                            pixel_sum_r_stage2 <= pixel_sum_r_stage2 + {8'b0, pixel_data_stage1[23:16], 8'b0};
                            pixel_sum_g_stage2 <= pixel_sum_g_stage2 + {8'b0, pixel_data_stage1[15:8], 8'b0};
                            pixel_sum_b_stage2 <= pixel_sum_b_stage2 + {8'b0, pixel_data_stage1[7:0], 8'b0};
                            
                            // Check if accumulation is complete
                            if (pixel_count_stage1 == 4'd3) begin
                                accumulation_complete_stage2 <= 1'b1;
                            end
                        end
                    end
                    2'b10: begin // Quarter resolution (4x4 averaging)
                        if (y_cnt_stage1 == 2'd0 && x_cnt_stage1 == 2'd0) begin
                            // First pixel in 4x4 block
                            pixel_sum_r_stage2 <= {8'b0, pixel_data_stage1[23:16], 8'b0};
                            pixel_sum_g_stage2 <= {8'b0, pixel_data_stage1[15:8], 8'b0};
                            pixel_sum_b_stage2 <= {8'b0, pixel_data_stage1[7:0], 8'b0};
                        end else begin
                            // Accumulate
                            pixel_sum_r_stage2 <= pixel_sum_r_stage2 + {8'b0, pixel_data_stage1[23:16], 8'b0};
                            pixel_sum_g_stage2 <= pixel_sum_g_stage2 + {8'b0, pixel_data_stage1[15:8], 8'b0};
                            pixel_sum_b_stage2 <= pixel_sum_b_stage2 + {8'b0, pixel_data_stage1[7:0], 8'b0};
                            
                            // Check if accumulation is complete
                            if (pixel_count_stage1 == 4'd15) begin
                                accumulation_complete_stage2 <= 1'b1;
                            end
                        end
                    end
                    default: begin
                        // Pass through
                        pixel_sum_r_stage2 <= {pixel_data_stage1[23:16], 16'b0};
                        pixel_sum_g_stage2 <= {pixel_data_stage1[15:8], 16'b0};
                        pixel_sum_b_stage2 <= {pixel_data_stage1[7:0], 16'b0};
                        accumulation_complete_stage2 <= 1'b1;
                    end
                endcase
            end
        end
    end

    // Stage 3: Averaging calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_sum_r_stage3 <= 24'd0;
            pixel_sum_g_stage3 <= 24'd0;
            pixel_sum_b_stage3 <= 24'd0;
            pixel_data_stage3 <= 24'd0;
            resolution_mode_stage3 <= 2'd0;
            frame_end_stage3 <= 1'b0;
            data_valid_stage3 <= 1'b0;
            pixel_count_stage3 <= 4'd0;
            accumulation_complete_stage3 <= 1'b0;
        end else begin
            pixel_sum_r_stage3 <= pixel_sum_r_stage2;
            pixel_sum_g_stage3 <= pixel_sum_g_stage2;
            pixel_sum_b_stage3 <= pixel_sum_b_stage2;
            pixel_data_stage3 <= pixel_data_stage2;
            resolution_mode_stage3 <= resolution_mode_stage2;
            frame_end_stage3 <= frame_end_stage2;
            data_valid_stage3 <= data_valid_stage2;
            pixel_count_stage3 <= pixel_count_stage2;
            accumulation_complete_stage3 <= accumulation_complete_stage2;
        end
    end

    // Stage 4: Output formatting
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_out_reg_stage4 <= 16'd0;
            out_valid_reg_stage4 <= 1'b0;
            frame_end_reg_stage4 <= 1'b0;
        end else begin
            // Default: maintain output valid until handshake completes
            if (out_valid_reg_stage4 && m_axis_tready) begin
                out_valid_reg_stage4 <= 1'b0;
                frame_end_reg_stage4 <= 1'b0;
            end
            
            if (data_valid_stage3 && accumulation_complete_stage3) begin
                case (resolution_mode_stage3)
                    2'b00: begin // Full resolution
                        pixel_out_reg_stage4 <= {pixel_data_stage3[23:19], pixel_data_stage3[15:10], pixel_data_stage3[7:3]};
                        out_valid_reg_stage4 <= 1'b1;
                        frame_end_reg_stage4 <= frame_end_stage3;
                    end
                    2'b01: begin // Half resolution (2x2 averaging)
                        // Average calculation (divide by 4)
                        pixel_out_reg_stage4 <= {pixel_sum_r_stage3[9:5], pixel_sum_g_stage3[9:4], pixel_sum_b_stage3[9:5]};
                        out_valid_reg_stage4 <= 1'b1;
                        frame_end_reg_stage4 <= frame_end_stage3;
                    end
                    2'b10: begin // Quarter resolution (4x4 averaging)
                        // Average calculation (divide by 16)
                        pixel_out_reg_stage4 <= {pixel_sum_r_stage3[11:7], pixel_sum_g_stage3[11:6], pixel_sum_b_stage3[11:7]};
                        out_valid_reg_stage4 <= 1'b1;
                        frame_end_reg_stage4 <= frame_end_stage3;
                    end
                    default: begin
                        // Pass through
                        pixel_out_reg_stage4 <= {pixel_data_stage3[23:19], pixel_data_stage3[15:10], pixel_data_stage3[7:3]};
                        out_valid_reg_stage4 <= 1'b1;
                        frame_end_reg_stage4 <= frame_end_stage3;
                    end
                endcase
            end
        end
    end
endmodule