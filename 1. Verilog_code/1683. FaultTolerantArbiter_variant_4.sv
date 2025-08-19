//SystemVerilog
module FaultTolerantArbiter (
    input clk, rst,
    input [3:0] req,
    output [3:0] ack,
    output [3:0] grant
);
wire [3:0] grant_a, grant_b;
wire [3:0] ack_a, ack_b;

ArbiterBase3 arb_a (
    .clk(clk),
    .rst(rst),
    .req(req),
    .ack(ack_a),
    .grant(grant_a)
);

ArbiterBase3 arb_b (
    .clk(clk),
    .rst(rst),
    .req(req),
    .ack(ack_b),
    .grant(grant_b)
);

assign grant = (grant_a == grant_b) ? grant_a : 4'b0000;
assign ack = ack_a & ack_b;
endmodule

module ArbiterBase3 (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] ack,
    output reg [3:0] grant
);
    integer i;
    reg found;
    reg [3:0] req_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant <= 0;
            ack <= 0;
            req_reg <= 0;
        end else begin
            req_reg <= req;
            grant <= 0;
            ack <= 0;
            found = 0;
            
            for (i = 0; i < 4; i = i + 1) begin
                if (!found && req_reg[i]) begin
                    grant[i] <= 1'b1;
                    ack[i] <= 1'b1;
                    found = 1;
                end
            end
        end
    end
endmodule