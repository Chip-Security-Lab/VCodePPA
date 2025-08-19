//SystemVerilog
module enabled_pattern_compare #(parameter DWIDTH = 16) (
    input clk, rst_n, en,
    input [DWIDTH-1:0] in_data, in_pattern,
    output reg match
);

    // Pipeline stage 1: Input registers
    reg [DWIDTH-1:0] data_stage1, pattern_stage1;
    reg en_stage1;
    
    // Pipeline stage 2: Comparison result
    reg compare_result_stage2;
    reg en_stage2;
    
    // Pipeline stage 3: Output
    reg match_stage3;
    reg en_stage3;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Stage 1: Input registration
    always @(posedge clk) begin
        if (!rst_n) begin
            data_stage1 <= {DWIDTH{1'b0}};
            pattern_stage1 <= {DWIDTH{1'b0}};
            en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= in_data;
            pattern_stage1 <= in_pattern;
            en_stage1 <= en;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Comparison
    always @(posedge clk) begin
        if (!rst_n) begin
            compare_result_stage2 <= 1'b0;
            en_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            compare_result_stage2 <= (data_stage1 == pattern_stage1);
            en_stage2 <= en_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clk) begin
        if (!rst_n) begin
            match_stage3 <= 1'b0;
            en_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            match_stage3 <= en_stage2 ? compare_result_stage2 : match_stage3;
            en_stage3 <= en_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Final output assignment
    always @(posedge clk) begin
        if (!rst_n)
            match <= 1'b0;
        else
            match <= match_stage3;
    end

endmodule