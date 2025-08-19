module int_ctrl_group #(GROUPS=2, WIDTH=4)(
    input clk, rst,
    input [GROUPS*WIDTH-1:0] int_in,
    input [GROUPS-1:0] group_en,
    output [GROUPS-1:0] group_int
);
genvar g;
generate
for(g=0; g<GROUPS; g=g+1) begin: group
    assign group_int[g] = |int_in[g*WIDTH +: WIDTH] & group_en[g];
end
endgenerate
endmodule