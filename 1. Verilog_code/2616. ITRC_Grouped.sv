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
    genvar g;
    generate
        for (g=0; g<GROUPS; g=g+1) begin : gen_group
            wire [GROUP_WIDTH-1:0] group_src = int_src[g*GROUP_WIDTH +: GROUP_WIDTH];
            always @(posedge clk) begin
                group_int[g] <= group_en[g] && (|group_src);
            end
        end
    endgenerate
endmodule