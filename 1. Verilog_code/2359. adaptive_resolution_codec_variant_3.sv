//SystemVerilog
`timescale 1ns / 1ps
//IEEE 1364-2005
module adaptive_resolution_codec (
    // Clock and Reset
    input  wire        aclk,
    input  wire        aresetn,
    
    // Input Interface with Valid-Ready Handshake
    input  wire [23:0] s_data,
    input  wire [2:0]  s_user,      // [1:0] resolution_mode, [2] line_end
    input  wire        s_last,      // frame_end
    input  wire        s_valid,
    output wire        s_ready,
    
    // Output Interface with Valid-Ready Handshake
    output wire [15:0] m_data,
    output wire        m_last,
    output wire        m_user,      // line_end indicator
    output wire        m_valid,
    input  wire        m_ready
);

    // Internal signals and registers
    reg [1:0]  x_cnt, y_cnt;
    reg [23:0] pixel_sum_r, pixel_sum_g, pixel_sum_b;
    reg [3:0]  pixel_count;
    reg [15:0] pixel_out_reg;
    reg        out_valid_reg;
    reg        m_last_reg;
    reg        m_user_reg;
    
    // Handshaking signals
    wire s_transfer = s_valid && s_ready;
    wire m_transfer = m_valid && m_ready;
    
    // Define ready/valid handshaking
    assign s_ready = !out_valid_reg || m_ready;
    assign m_valid = out_valid_reg;
    assign m_data = pixel_out_reg;
    assign m_last = m_last_reg;
    assign m_user = m_user_reg;
    
    // Extract control signals from input interface
    wire [1:0] resolution_mode = s_user[1:0];
    wire       line_end = s_user[2];
    wire       frame_end = s_last;
    
    // Buffered signals for high fanout nets
    // Data buffer registers
    reg [23:0] s_data_buf1, s_data_buf2;
    // Counter buffer registers
    reg [1:0]  x_cnt_buf1, x_cnt_buf2;
    reg [1:0]  y_cnt_buf1, y_cnt_buf2;
    // Pixel sum buffer registers
    reg [23:0] pixel_sum_r_buf1, pixel_sum_r_buf2;
    reg [23:0] pixel_sum_g_buf1, pixel_sum_g_buf2;
    
    // Buffer high fanout signals
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_data_buf1 <= 24'd0;
            s_data_buf2 <= 24'd0;
            x_cnt_buf1 <= 2'd0;
            x_cnt_buf2 <= 2'd0;
            y_cnt_buf1 <= 2'd0;
            y_cnt_buf2 <= 2'd0;
            pixel_sum_r_buf1 <= 24'd0;
            pixel_sum_r_buf2 <= 24'd0;
            pixel_sum_g_buf1 <= 24'd0;
            pixel_sum_g_buf2 <= 24'd0;
        end else begin
            s_data_buf1 <= s_data;
            s_data_buf2 <= s_data_buf1;
            x_cnt_buf1 <= x_cnt;
            x_cnt_buf2 <= x_cnt_buf1;
            y_cnt_buf1 <= y_cnt;
            y_cnt_buf2 <= y_cnt_buf1;
            pixel_sum_r_buf1 <= pixel_sum_r;
            pixel_sum_r_buf2 <= pixel_sum_r_buf1;
            pixel_sum_g_buf1 <= pixel_sum_g;
            pixel_sum_g_buf2 <= pixel_sum_g_buf1;
        end
    end
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            x_cnt <= 2'd0;
            y_cnt <= 2'd0;
            pixel_sum_r <= 24'd0;
            pixel_sum_g <= 24'd0;
            pixel_sum_b <= 24'd0;
            pixel_count <= 4'd0;
            pixel_out_reg <= 16'd0;
            out_valid_reg <= 1'b0;
            m_last_reg <= 1'b0;
            m_user_reg <= 1'b0;
        end else begin
            // Clear output valid if data was accepted
            if (m_transfer) begin
                out_valid_reg <= 1'b0;
                m_last_reg <= 1'b0;
                m_user_reg <= 1'b0;
            end
            
            // Handle frame and line synchronization
            if (s_transfer) begin
                if (frame_end) begin
                    x_cnt <= 2'd0;
                    y_cnt <= 2'd0;
                end else if (line_end) begin
                    x_cnt <= 2'd0;
                    y_cnt <= (y_cnt == 2'd3) ? 2'd0 : y_cnt + 2'd1;
                end
                
                // Process pixel data based on resolution mode
                case (resolution_mode)
                    2'b00: begin // Full resolution
                        pixel_out_reg <= {s_data_buf1[23:19], s_data_buf1[15:10], s_data_buf1[7:3]};
                        out_valid_reg <= 1'b1;
                        m_last_reg <= frame_end;
                        m_user_reg <= line_end;
                    end
                    2'b01: begin // Half resolution (2x2 averaging)
                        if (y_cnt_buf1[0] == 1'b0 && x_cnt_buf1[0] == 1'b0) begin
                            pixel_sum_r <= s_data_buf1[23:16];
                            pixel_sum_g <= s_data_buf1[15:8];
                            pixel_sum_b <= s_data_buf1[7:0];
                            pixel_count <= 4'd1;
                        end else begin
                            pixel_sum_r <= pixel_sum_r_buf1 + s_data_buf1[23:16];
                            pixel_sum_g <= pixel_sum_g_buf1 + s_data_buf1[15:8];
                            pixel_sum_b <= pixel_sum_b + s_data_buf1[7:0];
                            pixel_count <= pixel_count + 4'd1;
                            
                            if (pixel_count == 4'd3) begin
                                // Average and output
                                pixel_out_reg <= {pixel_sum_r_buf2[9:5] + s_data_buf2[23:19], 
                                                pixel_sum_g_buf2[9:4] + s_data_buf2[15:10], 
                                                pixel_sum_b[9:5] + s_data_buf2[7:3]};
                                out_valid_reg <= 1'b1;
                                pixel_count <= 4'd0;
                                m_last_reg <= frame_end;
                                m_user_reg <= line_end;
                            end
                        end
                    end
                    2'b10: begin // Quarter resolution (4x4 averaging)
                        if (y_cnt_buf2 == 2'd0 && x_cnt_buf2 == 2'd0) begin
                            pixel_sum_r <= s_data_buf2[23:16];
                            pixel_sum_g <= s_data_buf2[15:8];
                            pixel_sum_b <= s_data_buf2[7:0];
                            pixel_count <= 4'd1;
                        end else begin
                            pixel_sum_r <= pixel_sum_r_buf1 + s_data_buf2[23:16];
                            pixel_sum_g <= pixel_sum_g_buf1 + s_data_buf2[15:8];
                            pixel_sum_b <= pixel_sum_b + s_data_buf2[7:0];
                            pixel_count <= pixel_count + 4'd1;
                            
                            if (pixel_count == 4'd15) begin
                                // Average and output
                                pixel_out_reg <= {pixel_sum_r_buf2[11:7] + s_data_buf2[23:19], 
                                                pixel_sum_g_buf2[11:6] + s_data_buf2[15:10], 
                                                pixel_sum_b[11:7] + s_data_buf2[7:3]};
                                out_valid_reg <= 1'b1;
                                pixel_count <= 4'd0;
                                m_last_reg <= frame_end;
                                m_user_reg <= line_end;
                            end
                        end
                    end
                    default: begin
                        // Pass through
                        pixel_out_reg <= {s_data_buf1[23:19], s_data_buf1[15:10], s_data_buf1[7:3]};
                        out_valid_reg <= 1'b1;
                        m_last_reg <= frame_end;
                        m_user_reg <= line_end;
                    end
                endcase
                
                x_cnt <= (x_cnt == 2'd3) ? 2'd0 : x_cnt + 2'd1;
            end
        end
    end
endmodule