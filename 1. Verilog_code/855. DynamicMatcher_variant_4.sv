//SystemVerilog
module DynamicMatcher #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data,
    input wire load,
    input wire [WIDTH-1:0] new_pattern,
    output wire match,
    output wire valid
);

    // Pipeline stage signals
    reg [WIDTH-1:0] data_stage1;
    reg [WIDTH-1:0] pattern_stage1;
    reg load_stage1;
    reg valid_stage1;
    
    reg [WIDTH-1:0] data_stage2;
    reg [WIDTH-1:0] pattern_stage2;
    reg valid_stage2;
    
    reg [WIDTH-1:0] current_pattern;
    wire [WIDTH-1:0] pattern;
    wire match_result;
    
    // Stage 1: Pattern Register and Data Capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_pattern <= {WIDTH{1'b0}};
            data_stage1 <= {WIDTH{1'b0}};
            pattern_stage1 <= {WIDTH{1'b0}};
            load_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            if (load) begin
                current_pattern <= new_pattern;
            end
            data_stage1 <= data;
            pattern_stage1 <= current_pattern;
            load_stage1 <= load;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {WIDTH{1'b0}};
            pattern_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            pattern_stage2 <= pattern_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Match Generation
    assign match_result = (data_stage2 == pattern_stage2);
    assign match = match_result & valid_stage2;
    assign valid = valid_stage2;
    
endmodule