//SystemVerilog
module DoubleBufferMatcher #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire sel_buf,
    input wire [WIDTH-1:0] data,
    input wire [WIDTH-1:0] pattern0,
    input wire [WIDTH-1:0] pattern1,
    output wire match
);

    // Pipeline stage 1: Input registers
    reg [WIDTH-1:0] data_stage1;
    reg sel_buf_stage1;
    reg [WIDTH-1:0] pattern0_stage1;
    reg [WIDTH-1:0] pattern1_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Pattern selection
    reg [WIDTH-1:0] data_stage2;
    reg [WIDTH-1:0] selected_pattern_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3: Comparison
    reg match_result_stage3;
    reg valid_stage3;
    
    // Pipeline stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
            sel_buf_stage1 <= 1'b0;
            pattern0_stage1 <= {WIDTH{1'b0}};
            pattern1_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data;
            sel_buf_stage1 <= sel_buf;
            pattern0_stage1 <= pattern0;
            pattern1_stage1 <= pattern1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2: Pattern selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {WIDTH{1'b0}};
            selected_pattern_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            selected_pattern_stage2 <= sel_buf_stage1 ? pattern1_stage1 : pattern0_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_result_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            match_result_stage3 <= (data_stage2 == selected_pattern_stage2);
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignment
    assign match = valid_stage3 ? match_result_stage3 : 1'b0;

endmodule