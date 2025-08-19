//SystemVerilog
module FaultTolerantArbiter (
    input clk, rst,
    input [3:0] req,
    output [3:0] grant
);
    wire [3:0] grant_a, grant_b;
    wire arb_match;
    
    HanCarlsonArbiter arb_a (.clk(clk), .rst(rst), .req(req), .grant(grant_a));
    HanCarlsonArbiter arb_b (.clk(clk), .rst(rst), .req(req), .grant(grant_b));
    
    assign arb_match = &(grant_a ~^ grant_b);
    assign grant = arb_match ? grant_a : 4'b0000;
endmodule

module HanCarlsonArbiter (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);
    reg [3:0] temp_grant;
    reg [3:0] mask;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant <= 4'b0000;
            temp_grant <= 4'b0000;
            mask <= 4'b0000;
        end else begin
            temp_grant <= req;
            mask <= req;
            grant <= temp_grant & mask;
        end
    end
endmodule