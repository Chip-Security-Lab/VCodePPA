//SystemVerilog
// Top level module
module MuxHierarchy #(parameter W=4) (
    input [7:0][W-1:0] group,
    input [2:0] addr,
    output [W-1:0] data
);

wire [1:0][W-1:0] stage1;

// First stage mux
Stage1Mux #(.W(W)) stage1_inst (
    .group(group),
    .sel(addr[2]),
    .out(stage1)
);

// Second stage mux
Stage2Mux #(.W(W)) stage2_inst (
    .in(stage1),
    .sel(addr[1:0]),
    .out(data)
);

endmodule

// First stage 4:1 mux
module Stage1Mux #(parameter W=4) (
    input [7:0][W-1:0] group,
    input sel,
    output [1:0][W-1:0] out
);

assign out = sel ? group[7:4] : group[3:0];

endmodule

// Second stage 2:1 mux
module Stage2Mux #(parameter W=4) (
    input [1:0][W-1:0] in,
    input [1:0] sel,
    output [W-1:0] out
);

assign out = in[sel];

endmodule