//SystemVerilog
module DynMaskMatcher #(parameter WIDTH=8) (
    input clk,
    input rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    input [WIDTH-1:0] dynamic_mask,
    output reg match
);

    // Pipeline stage 1: Mask application
    reg [WIDTH-1:0] masked_data;
    reg [WIDTH-1:0] masked_pattern;
    
    // Pipeline stage 2: Comparison
    reg comparison_result;
    
    // Stage 1: Apply masks
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_data <= {WIDTH{1'b0}};
            masked_pattern <= {WIDTH{1'b0}};
        end else begin
            masked_data <= data & dynamic_mask;
            masked_pattern <= pattern & dynamic_mask;
        end
    end
    
    // Stage 2: Compare masked values
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comparison_result <= 1'b0;
        end else begin
            comparison_result <= (masked_data == masked_pattern);
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match <= 1'b0;
        end else begin
            match <= comparison_result;
        end
    end

endmodule