//SystemVerilog
module TreeArbiter #(parameter W=4) (
    input clk, rst,
    input [W-1:0] req,
    output [W-1:0] grant
);
    wire [1:0] l1_grant;
    wire [3:0] internal_grant;
    wire [1:0] l1_grant_reg;
    wire [1:0] l2_sel;

    // Level 1 Arbitration
    ArbiterBase #(2) L1_0 (.clk(clk), .rst(rst), .req(req[1:0]), .grant(l1_grant[0]));
    ArbiterBase #(2) L1_1 (.clk(clk), .rst(rst), .req(req[3:2]), .grant(l1_grant[1]));

    // Level 2 Control Logic
    Level2Control L2_CTRL (
        .clk(clk),
        .rst(rst),
        .l1_grant(l1_grant),
        .l1_grant_reg(l1_grant_reg),
        .l2_sel(l2_sel)
    );

    // Grant Generation
    GrantGenerator GRANT_GEN (
        .l1_grant_reg(l1_grant_reg),
        .l2_sel(l2_sel),
        .internal_grant(internal_grant)
    );

    assign grant = internal_grant[W-1:0];
endmodule

module Level2Control (
    input clk, rst,
    input [1:0] l1_grant,
    output reg [1:0] l1_grant_reg,
    output reg [1:0] l2_sel
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            l1_grant_reg <= 2'b0;
            l2_sel <= 2'b0;
        end else begin
            l1_grant_reg <= l1_grant;
            l2_sel <= (|l1_grant_reg) ? (l1_grant_reg[1]? 1 : 0) : l2_sel;
        end
    end
endmodule

module GrantGenerator (
    input [1:0] l1_grant_reg,
    input [1:0] l2_sel,
    output [3:0] internal_grant
);
    assign internal_grant = (l2_sel[0]) ? {l1_grant_reg[1], 2'b0, 1'b0} : {2'b0, l1_grant_reg[0], 1'b0};
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