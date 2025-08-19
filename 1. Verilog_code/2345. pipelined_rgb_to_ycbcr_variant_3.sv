//SystemVerilog
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
    
    // RGB components extraction
    wire [7:0] r_stage1, g_stage1, b_stage1;
    assign r_stage1 = rgb_stage1[23:16];
    assign g_stage1 = rgb_stage1[15:8];
    assign b_stage1 = rgb_stage1[7:0];
    
    // Stage 2 - Multiplication registers
    reg [15:0] r_66, g_129, b_25;  // For Y
    reg [15:0] r_n38, g_n74, b_112; // For Cb (n = negative)
    reg [15:0] r_112, g_n94, b_n18; // For Cr (n = negative)
    reg valid_stage2;
    
    // Stage 3 - Sum registers
    reg [15:0] y_sum_reg, cb_sum_reg, cr_sum_reg;
    reg valid_stage3;
    
    // Stage 4 - Shift registers
    reg [15:0] y_temp_reg, cb_temp_reg, cr_temp_reg;
    reg valid_stage4;
    
    // Final stage - Output registers
    reg [7:0] y_stage5, cb_stage5, cr_stage5;
    reg valid_stage5;
    
    // Computation signals - broken down to reduce critical path
    wire [15:0] y_sum = r_66 + g_129 + b_25 + 16'd128;
    wire [15:0] cb_sum = r_n38 + g_n74 + b_112 + 16'd128;
    wire [15:0] cr_sum = r_112 + g_n94 + b_n18 + 16'd128;
    
    wire [15:0] y_temp = (y_sum_reg >> 8) + 16;
    wire [15:0] cb_temp = (cb_sum_reg >> 8) + 128;
    wire [15:0] cr_temp = (cr_sum_reg >> 8) + 128;
    
    // Clamping logic
    wire [7:0] y_clamped = |y_temp_reg[15:8] ? 8'd255 : y_temp_reg[7:0];
    wire [7:0] cb_clamped = |cb_temp_reg[15:8] ? 8'd255 : cb_temp_reg[7:0];
    wire [7:0] cr_clamped = |cr_temp_reg[15:8] ? 8'd255 : cr_temp_reg[7:0];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            rgb_stage1 <= 24'b0;
            valid_stage1 <= 1'b0;
            
            // Reset multiplication registers
            r_66 <= 16'b0;
            g_129 <= 16'b0;
            b_25 <= 16'b0;
            r_n38 <= 16'b0;
            g_n74 <= 16'b0;
            b_112 <= 16'b0;
            r_112 <= 16'b0;
            g_n94 <= 16'b0;
            b_n18 <= 16'b0;
            valid_stage2 <= 1'b0;
            
            // Reset sum registers
            y_sum_reg <= 16'b0;
            cb_sum_reg <= 16'b0;
            cr_sum_reg <= 16'b0;
            valid_stage3 <= 1'b0;
            
            // Reset shift registers
            y_temp_reg <= 16'b0;
            cb_temp_reg <= 16'b0;
            cr_temp_reg <= 16'b0;
            valid_stage4 <= 1'b0;
            
            // Reset output registers
            y_stage5 <= 8'b0;
            cb_stage5 <= 8'b0;
            cr_stage5 <= 8'b0;
            valid_stage5 <= 1'b0;
            
            ycbcr_out <= 24'b0;
            out_valid <= 1'b0;
        end else begin
            // Pipeline stage 1: Register inputs
            rgb_stage1 <= rgb_in;
            valid_stage1 <= data_valid;
            
            // Pipeline stage 2: Pre-compute coefficient multiplications
            if (valid_stage1) begin
                // Y component coefficients
                r_66 <= 16'd66 * r_stage1;
                g_129 <= 16'd129 * g_stage1;
                b_25 <= 16'd25 * b_stage1;
                
                // Cb component coefficients
                r_n38 <= 16'd38 * (r_stage1 ^ 8'hFF); // 38 * (255 - r)
                g_n74 <= 16'd74 * (g_stage1 ^ 8'hFF); // 74 * (255 - g)
                b_112 <= 16'd112 * b_stage1;
                
                // Cr component coefficients
                r_112 <= 16'd112 * r_stage1;
                g_n94 <= 16'd94 * (g_stage1 ^ 8'hFF); // 94 * (255 - g)
                b_n18 <= 16'd18 * (b_stage1 ^ 8'hFF); // 18 * (255 - b)
            end
            valid_stage2 <= valid_stage1;
            
            // Pipeline stage 3: Sum calculation
            if (valid_stage2) begin
                y_sum_reg <= y_sum;
                cb_sum_reg <= cb_sum;
                cr_sum_reg <= cr_sum;
            end
            valid_stage3 <= valid_stage2;
            
            // Pipeline stage 4: Shift and offset
            if (valid_stage3) begin
                y_temp_reg <= y_temp;
                cb_temp_reg <= cb_temp;
                cr_temp_reg <= cr_temp;
            end
            valid_stage4 <= valid_stage3;
            
            // Pipeline stage 5: Clamping
            if (valid_stage4) begin
                y_stage5 <= y_clamped;
                cb_stage5 <= cb_clamped;
                cr_stage5 <= cr_clamped;
            end
            valid_stage5 <= valid_stage4;
            
            // Pipeline stage 6: Output
            ycbcr_out <= {y_stage5, cb_stage5, cr_stage5};
            out_valid <= valid_stage5;
        end
    end
endmodule