//SystemVerilog
module ITRC_HybridTrigger #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] level_int,
    input [WIDTH-1:0] edge_int,
    output reg [WIDTH-1:0] triggered
);

    // Stage 1 registers
    reg [WIDTH-1:0] level_int_stage1;
    reg [WIDTH-1:0] edge_int_stage1;
    reg [WIDTH-1:0] edge_reg_stage1;
    
    // Stage 2 registers
    reg [WIDTH-1:0] edge_diff_stage2;
    reg [WIDTH-1:0] edge_detect_stage2;
    reg [WIDTH-1:0] level_mask_stage2;
    
    // Stage 3 registers
    reg [WIDTH-1:0] triggered_stage3;

    // Stage 1: Input registration
    always @(posedge clk) begin
        if (!rst_n) begin
            level_int_stage1 <= {WIDTH{1'b0}};
            edge_int_stage1 <= {WIDTH{1'b0}};
            edge_reg_stage1 <= {WIDTH{1'b0}};
        end else begin
            level_int_stage1 <= level_int;
            edge_int_stage1 <= edge_int;
            edge_reg_stage1 <= edge_int_stage1;
        end
    end

    // Stage 2: Edge detection and level masking
    always @(posedge clk) begin
        if (!rst_n) begin
            edge_diff_stage2 <= {WIDTH{1'b0}};
            edge_detect_stage2 <= {WIDTH{1'b0}};
            level_mask_stage2 <= {WIDTH{1'b0}};
        end else begin
            edge_diff_stage2 <= edge_int_stage1 ^ edge_reg_stage1;
            edge_detect_stage2 <= edge_diff_stage2 & edge_int_stage1;
            level_mask_stage2 <= level_int_stage1 & edge_int_stage1;
        end
    end

    // Stage 3: Trigger output
    always @(posedge clk) begin
        if (!rst_n)
            triggered_stage3 <= {WIDTH{1'b0}};
        else
            triggered_stage3 <= edge_detect_stage2 | level_mask_stage2;
    end

    // Output assignment
    always @(posedge clk) begin
        if (!rst_n)
            triggered <= {WIDTH{1'b0}};
        else
            triggered <= triggered_stage3;
    end

endmodule