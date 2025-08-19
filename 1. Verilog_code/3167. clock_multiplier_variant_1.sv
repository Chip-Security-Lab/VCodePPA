//SystemVerilog
module clock_multiplier(
    input ref_clk,
    input resetn,
    output reg out_clk
);
    // Pipeline stage registers
    reg [1:0] count_stage1;
    reg [1:0] count_stage2;
    reg int_clk_stage1;
    reg int_clk_stage2;
    reg int_clk_stage3;
    reg out_clk_toggle_stage1;
    reg out_clk_toggle_stage2;
    reg out_clk_toggle_stage3;
    
    // Internal pipeline signals
    reg count_match_stage1;
    reg count_match_stage2;
    reg int_clk_rising_stage1;
    reg int_clk_rising_stage2;
    
    // Stage 1: Counter logic
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn) begin
            count_stage1 <= 2'd0;
            count_match_stage1 <= 1'b0;
        end else begin
            count_stage1 <= count_stage1 + 1'b1;
            count_match_stage1 <= (count_stage1 == 2'd1) || (count_stage1 == 2'd3);
        end
    end
    
    // Stage 2: Internal clock generation
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn) begin
            count_stage2 <= 2'd0;
            count_match_stage2 <= 1'b0;
            int_clk_stage1 <= 1'b0;
            int_clk_rising_stage1 <= 1'b0;
        end else begin
            count_stage2 <= count_stage1;
            count_match_stage2 <= count_match_stage1;
            
            if (count_match_stage1) begin
                int_clk_stage1 <= ~int_clk_stage1;
            end
            
            int_clk_rising_stage1 <= count_match_stage1 && ~int_clk_stage1;
        end
    end
    
    // Stage 3: Toggle logic
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn) begin
            int_clk_stage2 <= 1'b0;
            int_clk_rising_stage2 <= 1'b0;
            out_clk_toggle_stage1 <= 1'b0;
        end else begin
            int_clk_stage2 <= int_clk_stage1;
            int_clk_rising_stage2 <= int_clk_rising_stage1;
            
            if (int_clk_rising_stage1) begin
                out_clk_toggle_stage1 <= ~out_clk_toggle_stage1;
            end
        end
    end
    
    // Stage 4: Output clock generation
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn) begin
            int_clk_stage3 <= 1'b0;
            out_clk_toggle_stage2 <= 1'b0;
            out_clk_toggle_stage3 <= 1'b0;
            out_clk <= 1'b0;
        end else begin
            int_clk_stage3 <= int_clk_stage2;
            out_clk_toggle_stage2 <= out_clk_toggle_stage1;
            out_clk_toggle_stage3 <= out_clk_toggle_stage2;
            
            if (int_clk_rising_stage2 && out_clk_toggle_stage2) begin
                out_clk <= ~out_clk;
            end
        end
    end
endmodule