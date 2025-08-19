module TreeArbiter #(parameter W=4) (
    input clk, rst,
    input [W-1:0] req,
    output [W-1:0] grant
);
wire [1:0] l1_grant;
reg [1:0] l2_sel;
wire [3:0] internal_grant;

// Level 1: 4 groups
ArbiterBase #(2) L1_0 (.clk(clk), .rst(rst), .req(req[1:0]), .grant(l1_grant[0]));
ArbiterBase #(2) L1_1 (.clk(clk), .rst(rst), .req(req[3:2]), .grant(l1_grant[1]));

// Level 2
always @(posedge clk) 
    l2_sel <= (|l1_grant) ? (l1_grant[1]? 1 : 0) : l2_sel;

assign internal_grant = (l2_sel[0]) ? {l1_grant[1], 2'b0, 1'b0} : {2'b0, l1_grant[0], 1'b0};
assign grant = internal_grant[W-1:0];
endmodule

// 基础仲裁器模块
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