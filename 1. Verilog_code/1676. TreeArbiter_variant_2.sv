//SystemVerilog
module TreeArbiter #(parameter W=4) (
    input clk, rst,
    input [W-1:0] req,
    output [W-1:0] grant
);
reg [1:0] l1_grant;
reg [1:0] l2_sel;
reg [3:0] internal_grant;
wire [1:0] l1_borrow;
wire [1:0] l2_borrow;

// Level 1: 4 groups
ArbiterBase #(2) L1_0 (.clk(clk), .rst(rst), .req(req[1:0]), .grant(l1_grant[0]));
ArbiterBase #(2) L1_1 (.clk(clk), .rst(rst), .req(req[3:2]), .grant(l1_grant[1]));

// Level 2 with carry-lookahead subtraction
assign l1_borrow[0] = ~l1_grant[0] & l1_grant[1];
assign l1_borrow[1] = ~l1_grant[1] & l1_grant[0];
assign l2_borrow[0] = l1_borrow[0] | (l1_borrow[1] & l1_grant[0]);
assign l2_borrow[1] = l1_borrow[1] | (l1_borrow[0] & l1_grant[1]);

always @(posedge clk) begin
    if (rst) begin
        l2_sel <= 2'b0;
        internal_grant <= 4'b0;
    end else begin
        if (|l1_grant) begin
            l2_sel <= l2_borrow[1] ? 2'b01 : 2'b00;
        end else begin
            l2_sel <= l2_sel;
        end

        if (l2_sel[0]) begin
            internal_grant <= {l1_grant[1], 2'b0, 1'b0};
        end else begin
            internal_grant <= {2'b0, l1_grant[0], 1'b0};
        end
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