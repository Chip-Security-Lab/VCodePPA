//SystemVerilog
module sync_pattern_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in, pattern,
    input valid_in,
    output reg match_out,
    output reg valid_out
);
    // Pipeline stages
    reg [WIDTH-1:0] data_in_stage1, pattern_stage1;
    reg valid_stage1;
    
    reg [WIDTH-1:0] data_in_stage2, pattern_stage2;
    reg valid_stage2;
    
    reg match_stage3;
    reg valid_stage3;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= {WIDTH{1'b0}};
            pattern_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            pattern_stage1 <= pattern;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Pattern comparison preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage2 <= {WIDTH{1'b0}};
            pattern_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            pattern_stage2 <= pattern_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Pattern matching and output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            match_stage3 <= (data_in_stage2 == pattern_stage2);
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            match_out <= match_stage3;
            valid_out <= valid_stage3;
        end
    end
endmodule