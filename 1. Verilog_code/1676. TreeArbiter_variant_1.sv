//SystemVerilog
module TreeArbiter #(parameter W=4) (
    input clk, rst,
    input [W-1:0] req,
    output [W-1:0] grant
);
reg [1:0] l1_grant;
reg [1:0] l2_sel;
reg [3:0] internal_grant;
wire [1:0] l1_grant_comp;
wire [1:0] l2_sel_comp;

// Level 1: 4 groups
ArbiterBase #(2) L1_0 (.clk(clk), .rst(rst), .req(req[1:0]), .grant(l1_grant[0]));
ArbiterBase #(2) L1_1 (.clk(clk), .rst(rst), .req(req[3:2]), .grant(l1_grant[1]));

// Level 2
assign l1_grant_comp = ~l1_grant + 1'b1;
assign l2_sel_comp = ~l2_sel + 1'b1;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        l2_sel <= 2'b0;
        internal_grant <= 4'b0;
    end else begin
        l2_sel <= (|l1_grant) ? (l1_grant[1]? 1 : 0) : l2_sel;
        internal_grant <= (l2_sel[0]) ? {l1_grant[1], 2'b0, 1'b0} : {2'b0, l1_grant[0], 1'b0};
    end
end

assign grant = internal_grant[W-1:0];
endmodule

module ArbiterBase #(parameter WIDTH=2) (
    input clk, rst,
    input [WIDTH-1:0] req,
    output reg grant
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            grant <= 1'b0;
        else
            grant <= |req;
    end
endmodule