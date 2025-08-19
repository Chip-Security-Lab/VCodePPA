module FaultTolerantArbiter (
    input clk, rst,
    input [3:0] req,
    output [3:0] grant
);
wire [3:0] grant_a, grant_b;
ArbiterBase3 arb_a (.clk(clk), .rst(rst), .req(req), .grant(grant_a));
ArbiterBase3 arb_b (.clk(clk), .rst(rst), .req(req), .grant(grant_b));

assign grant = (grant_a == grant_b) ? grant_a : 4'b0000;
endmodule

// Basic Arbiter implementation
module ArbiterBase3 (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);
    integer i;
    reg found;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            grant <= 0;
        else begin
            grant <= 0;
            found = 0;
            for (i = 0; i < 4; i = i + 1) begin
                if (!found && req[i]) begin
                    grant[i] <= 1'b1;
                    found = 1;
                end
            end
        end
    end
endmodule