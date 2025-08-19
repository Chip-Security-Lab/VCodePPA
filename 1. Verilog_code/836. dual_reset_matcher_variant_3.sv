//SystemVerilog
module dual_reset_matcher #(parameter W = 8) (
    input clk, sync_rst, async_rst_n,
    input [W-1:0] data, template,
    input qualify,
    output reg valid_match
);

    // Stage 1 registers
    reg [W-1:0] data_stage1, template_stage1;
    reg qualify_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg match_stage2;
    reg qualify_stage2;
    reg valid_stage2;

    // Stage 1: Data capture
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            data_stage1 <= {W{1'b0}};
            template_stage1 <= {W{1'b0}};
            qualify_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else if (sync_rst) begin
            data_stage1 <= {W{1'b0}};
            template_stage1 <= {W{1'b0}};
            qualify_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            data_stage1 <= data;
            template_stage1 <= template;
            qualify_stage1 <= qualify;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Comparison
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            match_stage2 <= 1'b0;
            qualify_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else if (sync_rst) begin
            match_stage2 <= 1'b0;
            qualify_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            match_stage2 <= (data_stage1 == template_stage1);
            qualify_stage2 <= qualify_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Final output
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            valid_match <= 1'b0;
        else if (sync_rst)
            valid_match <= 1'b0;
        else
            valid_match <= match_stage2 & qualify_stage2 & valid_stage2;
    end

endmodule