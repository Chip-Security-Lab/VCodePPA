//SystemVerilog
/////////////////////////////////////////////////////////
// Module: async_rgb565_codec
// Description: Converts 24-bit RGB to 16-bit RGB565 format with optional alpha channel
// Standard: IEEE 1364-2005
/////////////////////////////////////////////////////////
module async_rgb565_codec (
    input wire        clk,          // System clock
    input wire        rst_n,        // Active low reset
    input wire [23:0] rgb_in,       // 24-bit RGB input (R[23:16], G[15:8], B[7:0])
    input wire        alpha_en,     // Alpha channel enable
    input wire        data_valid,   // Input data valid signal
    output reg [15:0] rgb565_out,   // 16-bit RGB565 output
    output reg        out_valid     // Output data valid signal
);

    // Pipeline stage 1 registers
    reg [7:0] r_stage1;
    reg [7:0] g_stage1;
    reg [7:0] b_stage1;
    reg       alpha_en_stage1;
    reg       valid_stage1;

    // Pipeline stage 2 registers
    reg [4:0] r_stage2;    // 5-bit red component
    reg [5:0] g_stage2;    // 6-bit green component
    reg [4:0] b_stage2;    // 5-bit blue component
    reg       alpha_en_stage2;
    reg       valid_stage2;

    // Pipeline stage 1: Register inputs and extract RGB components
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_stage1 <= 8'h0;
            g_stage1 <= 8'h0;
            b_stage1 <= 8'h0;
            alpha_en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            r_stage1 <= rgb_in[23:16];
            g_stage1 <= rgb_in[15:8];
            b_stage1 <= rgb_in[7:0];
            alpha_en_stage1 <= alpha_en;
            valid_stage1 <= data_valid;
        end
    end

    // Pipeline stage 2: Convert to RGB565 bit widths
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_stage2 <= 5'h0;
            g_stage2 <= 6'h0;
            b_stage2 <= 5'h0;
            alpha_en_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            r_stage2 <= r_stage1[7:3];    // Extract 5 MSBs of red
            g_stage2 <= g_stage1[7:2];    // Extract 6 MSBs of green
            b_stage2 <= b_stage1[7:3];    // Extract 5 MSBs of blue
            alpha_en_stage2 <= alpha_en_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Pipeline stage 3: Format final RGB565 output with optional alpha bit
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565_out <= 16'h0;
            out_valid <= 1'b0;
        end else begin
            if (valid_stage2) begin
                // Format RGB565 with optional alpha bit
                rgb565_out <= alpha_en_stage2 ? {1'b1, r_stage2, g_stage2, b_stage2} : 
                                              {r_stage2, g_stage2, b_stage2};
            end
            out_valid <= valid_stage2;
        end
    end

endmodule