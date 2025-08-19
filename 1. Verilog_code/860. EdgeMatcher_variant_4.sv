//SystemVerilog
module EdgeMatcher #(parameter WIDTH=8) (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] pattern,
    output wire edge_match,
    output wire valid_out
);

    // Stage 1 registers
    reg [WIDTH-1:0] data_in_stage1;
    reg [WIDTH-1:0] pattern_stage1;
    reg valid_stage1;
    reg match_stage1;
    
    // Stage 2 registers
    reg match_stage2;
    reg last_match_stage2;
    reg valid_stage2;
    
    // Stage 1: Capture inputs and perform equality comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= {WIDTH{1'b0}};
            pattern_stage1 <= {WIDTH{1'b0}};
            match_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            pattern_stage1 <= pattern;
            match_stage1 <= (data_in == pattern);
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Store last match state and determine edge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_stage2 <= 1'b0;
            last_match_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            match_stage2 <= match_stage1;
            last_match_stage2 <= match_stage2;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output assignment
    assign edge_match = match_stage2 && !last_match_stage2;
    assign valid_out = valid_stage2;

endmodule