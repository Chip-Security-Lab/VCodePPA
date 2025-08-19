//SystemVerilog
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
    // Stage 1 - Input Buffering & Format Selection
    reg [23:0] rgb_data_stage1;
    reg [7:0] mono_data_stage1;
    reg [15:0] yuv_data_stage1;
    reg [2:0] format_select_stage1;
    reg priority_override_stage1;
    reg [2:0] active_fmt_stage1;
    
    // Stage 2 - Component Extraction
    reg [4:0] rgb_r_stage2;    // Red component 
    reg [5:0] rgb_g_stage2;    // Green component
    reg [4:0] rgb_b_stage2;    // Blue component
    reg [7:0] mono_stage2;     // Mono data
    reg [15:0] yuv_stage2;     // YUV data
    reg [2:0] active_fmt_stage2;
    
    // Stage 3 - Format Processing
    reg [15:0] rgb_processed_stage3;
    reg [15:0] mono_processed_stage3;
    reg [15:0] yuv_processed_stage3;
    reg [2:0] active_fmt_stage3;
    
    // Stage 4 - Output Selection
    reg [15:0] display_out_stage4;
    reg format_valid_stage4;

    // Stage 1: Input Buffering & Format Selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb_data_stage1 <= 24'h000000;
            mono_data_stage1 <= 8'h00;
            yuv_data_stage1 <= 16'h0000;
            format_select_stage1 <= 3'b000;
            priority_override_stage1 <= 1'b0;
            active_fmt_stage1 <= 3'b000;
        end else begin
            rgb_data_stage1 <= rgb_data;
            mono_data_stage1 <= mono_data;
            yuv_data_stage1 <= yuv_data;
            format_select_stage1 <= format_select;
            priority_override_stage1 <= priority_override;
            active_fmt_stage1 <= priority_override ? 3'b000 : format_select;
        end
    end
    
    // Stage 2: Component Extraction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb_r_stage2 <= 5'b00000;
            rgb_g_stage2 <= 6'b000000;
            rgb_b_stage2 <= 5'b00000;
            mono_stage2 <= 8'h00;
            yuv_stage2 <= 16'h0000;
            active_fmt_stage2 <= 3'b000;
        end else begin
            rgb_r_stage2 <= rgb_data_stage1[23:19];
            rgb_g_stage2 <= rgb_data_stage1[15:10];
            rgb_b_stage2 <= rgb_data_stage1[7:3];
            mono_stage2 <= mono_data_stage1;
            yuv_stage2 <= yuv_data_stage1;
            active_fmt_stage2 <= active_fmt_stage1;
        end
    end
    
    // Stage 3: Format Processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb_processed_stage3 <= 16'h0000;
            mono_processed_stage3 <= 16'h0000;
            yuv_processed_stage3 <= 16'h0000;
            active_fmt_stage3 <= 3'b000;
        end else begin
            rgb_processed_stage3 <= {rgb_r_stage2, rgb_g_stage2, rgb_b_stage2};
            mono_processed_stage3 <= {mono_stage2, mono_stage2};
            yuv_processed_stage3 <= yuv_stage2;
            active_fmt_stage3 <= active_fmt_stage2;
        end
    end
    
    // Stage 4: Output Selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            display_out_stage4 <= 16'h0000;
            format_valid_stage4 <= 1'b0;
        end else begin
            case (active_fmt_stage3)
                3'b000: begin // RGB mode
                    display_out_stage4 <= rgb_processed_stage3;
                    format_valid_stage4 <= 1'b1;
                end
                3'b001: begin // Mono mode
                    display_out_stage4 <= mono_processed_stage3;
                    format_valid_stage4 <= 1'b1;
                end
                3'b010: begin // YUV mode
                    display_out_stage4 <= yuv_processed_stage3;
                    format_valid_stage4 <= 1'b1;
                end
                default: begin // Invalid formats
                    display_out_stage4 <= 16'h0000;
                    format_valid_stage4 <= 1'b0;
                end
            endcase
        end
    end
    
    // Final Output Registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            display_out <= 16'h0000;
            format_valid <= 1'b0;
        end else begin
            display_out <= display_out_stage4;
            format_valid <= format_valid_stage4;
        end
    end
endmodule