//SystemVerilog
module clock_derived_square(
    input main_clk,
    input reset,
    output reg [3:0] clk_div_out
);
    // Stage 1: Counter pipeline
    reg [7:0] div_counter_stage1;
    reg valid_stage1;
    
    // Stage 2: Select bits pipeline
    reg [7:0] div_counter_stage2;
    reg valid_stage2;
    
    // Stage 3: Output pipeline
    reg [3:0] clk_div_out_stage3;
    reg valid_stage3;
    
    // Stage 1: Counter logic
    always @(posedge main_clk) begin
        if (reset) begin
            div_counter_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
        end else begin
            div_counter_stage1 <= div_counter_stage1 + 8'd1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Bit selection stage
    always @(posedge main_clk) begin
        if (reset) begin
            div_counter_stage2 <= 8'd0;
            valid_stage2 <= 1'b0;
        end else begin
            div_counter_stage2 <= div_counter_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Output formation
    always @(posedge main_clk) begin
        if (reset) begin
            clk_div_out_stage3 <= 4'b0000;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            clk_div_out_stage3[0] <= div_counter_stage2[0];  // Divide by 2
            clk_div_out_stage3[1] <= div_counter_stage2[1];  // Divide by 4
            clk_div_out_stage3[2] <= div_counter_stage2[3];  // Divide by 16
            clk_div_out_stage3[3] <= div_counter_stage2[5];  // Divide by 64
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Final output register
    always @(posedge main_clk) begin
        if (reset) begin
            clk_div_out <= 4'b0000;
        end else if (valid_stage3) begin
            clk_div_out <= clk_div_out_stage3;
        end
    end
endmodule