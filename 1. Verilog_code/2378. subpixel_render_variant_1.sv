//SystemVerilog
//===================================================================
// Module: subpixel_render
// Description: Pipelined subpixel rendering module with improved
//              data path organization and timing, and clock/signal
//              buffering to reduce fanout issues
//===================================================================
module subpixel_render (
    input wire clk,           // System clock
    input wire rst_n,         // Active low reset
    input wire [7:0] px1,     // First pixel input 
    input wire [7:0] px2,     // Second pixel input
    input wire valid_in,      // Input data valid
    output reg [7:0] px_out,  // Output pixel
    output reg valid_out      // Output data valid
);

    // Clock buffer tree to reduce fanout
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // Buffer the clock to reduce fanout
    assign clk_buf1 = clk;
    assign clk_buf2 = clk;
    assign clk_buf3 = clk;
    
    // Buffered reset signal
    wire rst_n_buf1, rst_n_buf2, rst_n_buf3;
    
    // Buffer the reset to reduce fanout
    assign rst_n_buf1 = rst_n;
    assign rst_n_buf2 = rst_n;
    assign rst_n_buf3 = rst_n;

    // Stage 1: Input registration and scaling
    reg [9:0] px1_scaled_r;   // 8-bit * 3 requires 10 bits
    reg [7:0] px2_scaled_r;   // 8-bit * 1 remains 8 bits
    reg valid_s1;
    
    // Stage 2: Addition pipeline registers
    reg [10:0] px_sum_r;      // 11 bits to hold sum of scaled values
    reg valid_s2;
    
    // Stage 1 logic: Scale pixels
    always @(posedge clk_buf1 or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            px1_scaled_r <= 10'b0;
            px2_scaled_r <= 8'b0;
            valid_s1 <= 1'b0;
        end else begin
            px1_scaled_r <= {2'b00, px1} + {px1, 1'b0};  // px1 * 3 (px1 + px1*2)
            px2_scaled_r <= px2;  // px2 * 1
            valid_s1 <= valid_in;
        end
    end
    
    // Stage 2 logic: Sum scaled pixels
    always @(posedge clk_buf2 or negedge rst_n_buf2) begin
        if (!rst_n_buf2) begin
            px_sum_r <= 11'b0;
            valid_s2 <= 1'b0;
        end else begin
            px_sum_r <= {1'b0, px1_scaled_r} + {3'b000, px2_scaled_r};
            valid_s2 <= valid_s1;
        end
    end
    
    // Stage 3 logic: Perform division and output
    always @(posedge clk_buf3 or negedge rst_n_buf3) begin
        if (!rst_n_buf3) begin
            px_out <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            px_out <= px_sum_r[10:2];  // Divide by 4 (shift right by 2)
            valid_out <= valid_s2;
        end
    end

endmodule