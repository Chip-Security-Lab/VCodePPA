//SystemVerilog
module pipelined_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in, pattern,
    output reg match_out
);

    // Pipeline stage 1: Input data registration
    reg [WIDTH-1:0] data_reg_stage1;
    reg [WIDTH-1:0] pattern_reg_stage1;
    
    // Pipeline stage 2: Pattern complement calculation
    reg [WIDTH-1:0] twos_comp_pattern_stage2;
    reg [WIDTH-1:0] data_reg_stage2;
    
    // Pipeline stage 3: Difference calculation
    reg [WIDTH-1:0] diff_result_stage3;
    
    // Pipeline stage 4: Zero detection and match output
    reg is_zero_stage4;
    reg match_out_stage4;

    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg_stage1 <= 0;
            pattern_reg_stage1 <= 0;
        end else begin
            data_reg_stage1 <= data_in;
            pattern_reg_stage1 <= pattern;
        end
    end

    // Stage 2: Pattern complement calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            twos_comp_pattern_stage2 <= 0;
            data_reg_stage2 <= 0;
        end else begin
            twos_comp_pattern_stage2 <= ~pattern_reg_stage1 + 1'b1;
            data_reg_stage2 <= data_reg_stage1;
        end
    end

    // Stage 3: Difference calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_result_stage3 <= 0;
        end else begin
            diff_result_stage3 <= data_reg_stage2 + twos_comp_pattern_stage2;
        end
    end

    // Stage 4: Zero detection and match output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_zero_stage4 <= 0;
            match_out_stage4 <= 0;
            match_out <= 0;
        end else begin
            is_zero_stage4 <= (diff_result_stage3 == {WIDTH{1'b0}});
            match_out_stage4 <= is_zero_stage4;
            match_out <= match_out_stage4;
        end
    end

endmodule