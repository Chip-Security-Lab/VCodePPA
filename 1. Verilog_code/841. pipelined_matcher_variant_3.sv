//SystemVerilog
module pipelined_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in, pattern,
    output reg match_out
);
    // Stage 1 registers
    reg [WIDTH-1:0] data_stage1;
    reg [WIDTH-1:0] pattern_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [WIDTH-1:0] inverted_pattern_stage2;
    reg [WIDTH-1:0] data_stage2;
    reg valid_stage2;
    
    // Stage 3 registers
    reg [WIDTH:0] diff_stage3;
    reg valid_stage3;
    
    // Stage 4 registers
    reg comp_result_stage4;
    reg valid_stage4;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Stage 1 reset
            data_stage1 <= 0;
            pattern_stage1 <= 0;
            valid_stage1 <= 0;
            
            // Stage 2 reset
            inverted_pattern_stage2 <= 0;
            data_stage2 <= 0;
            valid_stage2 <= 0;
            
            // Stage 3 reset
            diff_stage3 <= 0;
            valid_stage3 <= 0;
            
            // Stage 4 reset
            comp_result_stage4 <= 0;
            valid_stage4 <= 0;
            
            match_out <= 0;
        end else begin
            // Stage 1: Input registration
            data_stage1 <= data_in;
            pattern_stage1 <= pattern;
            valid_stage1 <= 1'b1;
            
            // Stage 2: Pattern inversion
            inverted_pattern_stage2 <= ~pattern_stage1 + 1'b1;
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
            
            // Stage 3: Difference calculation
            diff_stage3 <= {1'b0, data_stage2} + {1'b0, inverted_pattern_stage2};
            valid_stage3 <= valid_stage2;
            
            // Stage 4: Comparison
            comp_result_stage4 <= (diff_stage3[WIDTH-1:0] == 0);
            valid_stage4 <= valid_stage3;
            
            // Output
            match_out <= valid_stage4 ? comp_result_stage4 : 1'b0;
        end
    end
endmodule