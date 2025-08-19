//SystemVerilog
module temp_compensated_codec (
    input clk, rst_n,
    input [7:0] r_in, g_in, b_in,
    input [7:0] temperature,
    input comp_enable,
    output reg [15:0] display_out,
    // Pipeline control signals
    input valid_in,
    output reg valid_out,
    input ready_in,
    output reg ready_out
);
    // Stage 1: Temperature comparison and factor calculation
    reg [7:0] r_in_stage1, g_in_stage1, b_in_stage1;
    reg comp_enable_stage1;
    reg [3:0] r_factor_stage1, g_factor_stage1, b_factor_stage1;
    reg valid_stage1;
    
    // Stage 2: Multiplication and adjustment
    reg [7:0] r_in_stage2, g_in_stage2, b_in_stage2;
    reg comp_enable_stage2;
    reg [3:0] r_factor_stage2, g_factor_stage2, b_factor_stage2;
    reg [11:0] r_product_stage2, g_product_stage2, b_product_stage2;
    reg [11:0] r_adj_stage2, g_adj_stage2, b_adj_stage2;
    reg valid_stage2;
    
    // Pre-compute temperature comparison results to reduce critical path
    wire temp_gt_80 = temperature > 8'd80;
    wire temp_gt_60 = temperature > 8'd60;
    wire temp_gt_40 = temperature > 8'd40;
    wire temp_gt_20 = temperature > 8'd20;
    
    // Stage 1: Register temperature factor calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_in_stage1 <= 8'h0;
            g_in_stage1 <= 8'h0;
            b_in_stage1 <= 8'h0;
            comp_enable_stage1 <= 1'b0;
            r_factor_stage1 <= 4'h0;
            g_factor_stage1 <= 4'h0;
            b_factor_stage1 <= 4'h0;
            valid_stage1 <= 1'b0;
            ready_out <= 1'b1;
        end
        else begin
            if (ready_out && valid_in) begin
                // Register input data
                r_in_stage1 <= r_in;
                g_in_stage1 <= g_in;
                b_in_stage1 <= b_in;
                comp_enable_stage1 <= comp_enable;
                valid_stage1 <= valid_in;
                
                // Red compensation factor calculation
                if (temp_gt_80)
                    r_factor_stage1 <= 4'd12;
                else if (temp_gt_60)
                    r_factor_stage1 <= 4'd13;
                else if (temp_gt_40)
                    r_factor_stage1 <= 4'd14;
                else
                    r_factor_stage1 <= 4'd15;
                
                // Green compensation factor calculation
                if (temp_gt_80)
                    g_factor_stage1 <= 4'd14;
                else if (temp_gt_60 || temp_gt_40)
                    g_factor_stage1 <= 4'd15;
                else if (temp_gt_20)
                    g_factor_stage1 <= 4'd14;
                else
                    g_factor_stage1 <= 4'd13;
                
                // Blue compensation factor calculation
                if (temp_gt_80)
                    b_factor_stage1 <= 4'd15;
                else if (temp_gt_60)
                    b_factor_stage1 <= 4'd14;
                else if (temp_gt_40)
                    b_factor_stage1 <= 4'd13;
                else if (temp_gt_20)
                    b_factor_stage1 <= 4'd12;
                else
                    b_factor_stage1 <= 4'd11;
            end
            else if (valid_stage1 && !valid_stage2) begin
                valid_stage1 <= 1'b0;
            end
            
            // Backpressure handling
            ready_out <= !valid_stage1 || valid_stage2;
        end
    end
    
    // Stage 2: Multiplication and adjustment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_in_stage2 <= 8'h0;
            g_in_stage2 <= 8'h0;
            b_in_stage2 <= 8'h0;
            comp_enable_stage2 <= 1'b0;
            r_factor_stage2 <= 4'h0;
            g_factor_stage2 <= 4'h0;
            b_factor_stage2 <= 4'h0;
            r_product_stage2 <= 12'h0;
            g_product_stage2 <= 12'h0;
            b_product_stage2 <= 12'h0;
            r_adj_stage2 <= 12'h0;
            g_adj_stage2 <= 12'h0;
            b_adj_stage2 <= 12'h0;
            valid_stage2 <= 1'b0;
        end
        else begin
            if (valid_stage1 && !valid_stage2) begin
                // Pass through the pipeline
                r_in_stage2 <= r_in_stage1;
                g_in_stage2 <= g_in_stage1;
                b_in_stage2 <= b_in_stage1;
                comp_enable_stage2 <= comp_enable_stage1;
                r_factor_stage2 <= r_factor_stage1;
                g_factor_stage2 <= g_factor_stage1;
                b_factor_stage2 <= b_factor_stage1;
                
                // Calculate color products with compensation factors
                r_product_stage2 <= r_in_stage1 * r_factor_stage1;
                g_product_stage2 <= g_in_stage1 * g_factor_stage1;
                b_product_stage2 <= b_in_stage1 * b_factor_stage1;
                
                valid_stage2 <= valid_stage1;
            end
            else if (valid_stage2 && ready_in) begin
                valid_stage2 <= 1'b0;
            end
            
            // Apply compensation based on comp_enable signal (calculated once)
            if (valid_stage1 && !valid_stage2) begin
                r_adj_stage2 <= comp_enable_stage1 ? (r_in_stage1 * r_factor_stage1) : {r_in_stage1, 4'b0000};
                g_adj_stage2 <= comp_enable_stage1 ? (g_in_stage1 * g_factor_stage1) : {g_in_stage1, 4'b0000};
                b_adj_stage2 <= comp_enable_stage1 ? (b_in_stage1 * b_factor_stage1) : {b_in_stage1, 4'b0000};
            end
        end
    end
    
    // Stage 3: Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            display_out <= 16'h0000;
            valid_out <= 1'b0;
        end
        else if (valid_stage2 && ready_in) begin
            // Convert adjusted RGB values to RGB565 format and register the output
            display_out <= {r_adj_stage2[11:7], g_adj_stage2[11:6], b_adj_stage2[11:7]};
            valid_out <= valid_stage2;
        end
        else if (valid_out && ready_in) begin
            valid_out <= 1'b0;
        end
    end
endmodule