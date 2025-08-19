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
    reg [2:0] active_fmt;
    reg [23:0] rgb_data_reg;
    reg [7:0] mono_data_reg;
    reg [15:0] yuv_data_reg;
    reg priority_override_reg;
    reg [2:0] format_select_reg;
    
    // Register input signals to improve timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb_data_reg <= 24'h000000;
            mono_data_reg <= 8'h00;
            yuv_data_reg <= 16'h0000;
            priority_override_reg <= 1'b0;
            format_select_reg <= 3'b000;
        end else begin
            rgb_data_reg <= rgb_data;
            mono_data_reg <= mono_data;
            yuv_data_reg <= yuv_data;
            priority_override_reg <= priority_override;
            format_select_reg <= format_select;
        end
    end
    
    // Format selection logic - moved after input registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_fmt <= 3'b000;
        end else begin
            active_fmt <= priority_override_reg ? 3'b000 : format_select_reg;
        end
    end
    
    // RGB converted output - registered
    reg [15:0] rgb_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb_out_reg <= 16'h0000;
        end else begin
            rgb_out_reg <= {rgb_data_reg[23:19], rgb_data_reg[15:10], rgb_data_reg[7:3]};
        end
    end
    
    // Mono converted output - registered
    reg [15:0] mono_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mono_out_reg <= 16'h0000;
        end else begin
            mono_out_reg <= {mono_data_reg, mono_data_reg};
        end
    end
    
    // YUV passthrough - registered
    reg [15:0] yuv_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yuv_out_reg <= 16'h0000;
        end else begin
            yuv_out_reg <= yuv_data_reg;
        end
    end
    
    // Output mux logic - now selects from registered outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            display_out <= 16'h0000;
            format_valid <= 1'b0;
        end else begin
            case (active_fmt)
                3'b000: begin // RGB mode
                    display_out <= rgb_out_reg;
                    format_valid <= 1'b1;
                end
                3'b001: begin // Mono mode
                    display_out <= mono_out_reg;
                    format_valid <= 1'b1;
                end
                3'b010: begin // YUV mode
                    display_out <= yuv_out_reg;
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