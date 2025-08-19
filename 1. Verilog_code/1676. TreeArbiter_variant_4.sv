//SystemVerilog
module TreeArbiter #(parameter W=4) (
    input clk, rst,
    input [W-1:0] req,
    output [W-1:0] grant
);

// Internal signals
wire [1:0] l1_grant;
reg [1:0] l2_sel;
reg [3:0] internal_grant_reg;

// Level 1 arbiters
ArbiterBase #(2) L1_0 (
    .clk(clk),
    .rst(rst),
    .req(req[1:0]),
    .grant(l1_grant[0])
);

ArbiterBase #(2) L1_1 (
    .clk(clk),
    .rst(rst),
    .req(req[3:2]),
    .grant(l1_grant[1])
);

// Level 2 selection logic
always @(posedge clk or posedge rst) begin
    if (rst) begin
        l2_sel <= 2'b0;
    end else if (|l1_grant) begin
        l2_sel <= l1_grant[1] ? 2'b01 : 2'b00;
    end
end

// Grant generation logic with register retiming
always @(posedge clk or posedge rst) begin
    if (rst) begin
        internal_grant_reg <= 4'b0;
    end else begin
        internal_grant_reg <= l2_sel[0] ? {l1_grant[1], 2'b0, 1'b0} : {2'b0, l1_grant[0], 1'b0};
    end
end

assign grant = internal_grant_reg[W-1:0];

endmodule

module ArbiterBase #(parameter WIDTH=2) (
    input clk, rst,
    input [WIDTH-1:0] req,
    output reg grant
);

// Request arbitration logic
always @(posedge clk or posedge rst) begin
    if (rst) begin
        grant <= 1'b0;
    end else begin
        grant <= |req;
    end
end

endmodule