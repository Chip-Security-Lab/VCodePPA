//SystemVerilog
module HybridArbiter #(parameter HP_GROUP=2) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);

wire [3:0] hp_req = req[3:2] ? {req[3:2], 2'b00} : 4'b0000;
wire [3:0] lp_req = req[1:0] ? {2'b00, req[1:0]} : 4'b0000;
reg [1:0] random_bit;

// Parallel prefix subtractor implementation
wire [3:0] hp_req_neg;
wire [3:0] p0, p1, p2, p3;
wire [3:0] g0, g1, g2, g3;
wire [3:0] c0, c1, c2, c3;

// Generate propagate and generate signals
assign p0 = hp_req[0] ^ 1'b1;
assign p1 = hp_req[1] ^ 1'b1;
assign p2 = hp_req[2] ^ 1'b1;
assign p3 = hp_req[3] ^ 1'b1;

assign g0 = ~hp_req[0];
assign g1 = ~hp_req[1];
assign g2 = ~hp_req[2];
assign g3 = ~hp_req[3];

// Parallel prefix computation
assign c0 = g0;
assign c1 = g1 | (p1 & c0);
assign c2 = g2 | (p2 & c1);
assign c3 = g3 | (p3 & c2);

// Final sum computation
assign hp_req_neg[0] = p0 ^ 1'b0;
assign hp_req_neg[1] = p1 ^ c0;
assign hp_req_neg[2] = p2 ^ c1;
assign hp_req_neg[3] = p3 ^ c2;

wire [1:0] req_state;
assign req_state = {|hp_req[3:2], |lp_req[1:0]};

always @(posedge clk) begin
    if(rst) begin
        grant <= 4'b0000;
        random_bit <= 2'b00;
    end else begin
        random_bit <= $urandom;
        case(req_state)
            2'b10: grant <= hp_req & hp_req_neg;
            2'b01: grant <= lp_req << random_bit[0];
            default: grant <= 4'b0000;
        endcase
    end
end

endmodule