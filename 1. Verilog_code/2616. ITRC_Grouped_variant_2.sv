//SystemVerilog
module ITRC_Grouped #(
    parameter GROUPS = 4,
    parameter GROUP_WIDTH = 4
)(
    input clk,
    input rst_n,
    input [GROUPS*GROUP_WIDTH-1:0] int_src,
    input [GROUPS-1:0] group_en,
    output reg [GROUPS-1:0] group_int
);

    // Pipeline stage 1: Input sampling
    reg [GROUPS*GROUP_WIDTH-1:0] int_src_stage1;
    reg [GROUPS-1:0] group_en_stage1;
    
    // Pipeline stage 2: Group OR computation
    reg [GROUPS-1:0] group_or_stage2;
    
    // Pipeline stage 3: Final AND and output
    reg [GROUPS-1:0] group_en_stage3;
    
    // Stage 1: Input sampling for interrupt sources
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_src_stage1 <= 0;
        end else begin
            int_src_stage1 <= int_src;
        end
    end
    
    // Stage 1: Input sampling for group enables
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            group_en_stage1 <= 0;
        end else begin
            group_en_stage1 <= group_en;
        end
    end
    
    // Stage 2: Group OR computation
    genvar g;
    generate
        for (g=0; g<GROUPS; g=g+1) begin : gen_group_or
            wire [GROUP_WIDTH-1:0] group_src = int_src_stage1[g*GROUP_WIDTH +: GROUP_WIDTH];
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    group_or_stage2[g] <= 0;
                end else begin
                    group_or_stage2[g] <= |group_src;
                end
            end
        end
    endgenerate
    
    // Stage 3: Group enable pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            group_en_stage3 <= 0;
        end else begin
            group_en_stage3 <= group_en_stage1;
        end
    end
    
    // Stage 3: Final output computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            group_int <= 0;
        end else begin
            group_int <= group_en_stage3 & group_or_stage2;
        end
    end

endmodule