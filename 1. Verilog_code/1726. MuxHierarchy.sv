module MuxHierarchy #(parameter W=4) (
    input [7:0][W-1:0] group,
    input [2:0] addr,
    output [W-1:0] data
);
wire [1:0][W-1:0] stage1 = addr[2] ? group[7:4] : group[3:0];
assign data = stage1[addr[1:0]];
endmodule