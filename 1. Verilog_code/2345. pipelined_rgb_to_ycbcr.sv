module pipelined_rgb_to_ycbcr (
    input clk, rst_n,
    input [23:0] rgb_in,
    input data_valid,
    output reg [23:0] ycbcr_out,
    output reg out_valid
);
    // Stage 1 - Input registers
    reg [23:0] rgb_stage1;
    reg valid_stage1;
    
    // Stage 2 - Computation registers
    reg [7:0] y_stage2, cb_stage2, cr_stage2;
    reg valid_stage2;
    
    // 临时计算变量
    reg [15:0] y_temp, cb_temp, cr_temp;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            rgb_stage1 <= 0; valid_stage1 <= 0;
            y_stage2 <= 0; cb_stage2 <= 0; cr_stage2 <= 0; valid_stage2 <= 0;
            ycbcr_out <= 0; out_valid <= 0;
        end else begin
            // Pipeline stage 1: Register inputs
            rgb_stage1 <= rgb_in;
            valid_stage1 <= data_valid;
            
            // Pipeline stage 2: Compute YCbCr
            if (valid_stage1) begin
                y_temp = ((16'd66 * rgb_stage1[23:16] + 16'd129 * rgb_stage1[15:8] + 
                           16'd25 * rgb_stage1[7:0] + 16'd128) >> 8) + 16;
                cb_temp = ((16'd38 * (rgb_stage1[23:16] ^ 8'hFF) + 16'd74 * (rgb_stage1[15:8] ^ 8'hFF) + 
                           16'd112 * rgb_stage1[7:0] + 16'd128) >> 8) + 128;
                cr_temp = ((16'd112 * rgb_stage1[23:16] + 16'd94 * (rgb_stage1[15:8] ^ 8'hFF) + 
                           16'd18 * (rgb_stage1[7:0] ^ 8'hFF) + 16'd128) >> 8) + 128;
                
                // Clamp to 8-bit range
                y_stage2 <= (y_temp > 255) ? 255 : y_temp[7:0];
                cb_stage2 <= (cb_temp > 255) ? 255 : cb_temp[7:0];
                cr_stage2 <= (cr_temp > 255) ? 255 : cr_temp[7:0];
            end
            valid_stage2 <= valid_stage1;
            
            // Pipeline stage 3: Output
            ycbcr_out <= {y_stage2, cb_stage2, cr_stage2};
            out_valid <= valid_stage2;
        end
    end
endmodule