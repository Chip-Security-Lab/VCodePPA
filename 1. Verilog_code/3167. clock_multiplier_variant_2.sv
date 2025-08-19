//SystemVerilog
module clock_multiplier(
    input ref_clk,
    input resetn,
    output reg out_clk
);
    // Pipeline stage 1: Counter and internal clock generation
    reg [1:0] count_stage1;
    reg int_clk_stage1;
    
    // Pipeline stage 2: Output clock generation
    reg int_clk_stage2;
    reg out_clk_stage2;
    
    // Pipeline stage 1 logic
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn) begin
            count_stage1 <= 2'd0;
            int_clk_stage1 <= 1'b0;
        end
        else if ((count_stage1 == 2'd1) || (count_stage1 == 2'd3)) begin
            count_stage1 <= count_stage1 + 1'b1;
            int_clk_stage1 <= ~int_clk_stage1;
        end
        else begin
            count_stage1 <= count_stage1 + 1'b1;
        end
    end
    
    // Pipeline stage 2 logic
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn) begin
            int_clk_stage2 <= 1'b0;
            out_clk_stage2 <= 1'b0;
        end
        else begin
            int_clk_stage2 <= int_clk_stage1;
            out_clk_stage2 <= ~out_clk_stage2;
        end
    end
    
    // Final output assignment
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn)
            out_clk <= 1'b0;
        else
            out_clk <= out_clk_stage2;
    end
endmodule