//SystemVerilog
module ITRC_Group #(
    parameter GROUP_WIDTH = 4
)(
    input clk,
    input rst_n,
    input [GROUP_WIDTH-1:0] int_src,
    input group_en,
    output reg group_int
);

    wire group_int_next = group_en && (|int_src);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            group_int <= 1'b0;
        else
            group_int <= group_int_next;
    end

endmodule

module ITRC_Grouped #(
    parameter GROUPS = 4,
    parameter GROUP_WIDTH = 4
)(
    input clk,
    input rst_n,
    input [GROUPS*GROUP_WIDTH-1:0] int_src,
    input [GROUPS-1:0] group_en,
    output [GROUPS-1:0] group_int
);

    genvar g;
    generate
        for (g=0; g<GROUPS; g=g+1) begin : gen_group
            wire [GROUP_WIDTH-1:0] group_src = int_src[g*GROUP_WIDTH +: GROUP_WIDTH];
            
            ITRC_Group #(
                .GROUP_WIDTH(GROUP_WIDTH)
            ) u_group (
                .clk(clk),
                .rst_n(rst_n),
                .int_src(group_src),
                .group_en(group_en[g]),
                .group_int(group_int[g])
            );
        end
    endgenerate

endmodule