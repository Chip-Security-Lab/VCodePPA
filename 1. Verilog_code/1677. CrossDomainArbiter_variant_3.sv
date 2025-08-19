//SystemVerilog
module CrossDomainArbiter #(parameter N=2) (
    input clk_a, clk_b, rst,
    input [N-1:0] req_a, req_b,
    output reg [N-1:0] grant
);

    // CDC Synchronization Module
    wire [N-1:0] sync_req_a, sync_req_b;
    CDC_Sync #(.WIDTH(N)) cdc_sync (
        .clk_a(clk_a),
        .clk_b(clk_b),
        .rst(rst),
        .req_a(req_a),
        .req_b(req_b),
        .sync_req_a(sync_req_a),
        .sync_req_b(sync_req_b)
    );

    // Request Combination Module
    wire [2*N-1:0] comb_req;
    RequestCombiner #(.N(N)) req_comb (
        .sync_req_a(sync_req_a),
        .sync_req_b(sync_req_b),
        .comb_req(comb_req)
    );

    // Arbitration Core
    wire [2*N-1:0] comb_grant;
    ArbiterCore #(.WIDTH(2*N)) arb_core (
        .clk(clk_a),
        .rst(rst),
        .req(comb_req),
        .grant(comb_grant)
    );

    // Grant Processing Module
    always @(posedge clk_a)
        grant <= comb_grant[N-1:0] | comb_grant[2*N-1:N];

endmodule

module CDC_Sync #(parameter WIDTH=2) (
    input clk_a, clk_b, rst,
    input [WIDTH-1:0] req_a, req_b,
    output reg [WIDTH-1:0] sync_req_a, sync_req_b
);

    reg [WIDTH-1:0] meta_sync_b;

    always @(posedge clk_a) 
        sync_req_a <= req_a;

    always @(posedge clk_a) begin
        meta_sync_b <= req_b;
        sync_req_b <= meta_sync_b;
    end

endmodule

module RequestCombiner #(parameter N=2) (
    input [N-1:0] sync_req_a, sync_req_b,
    output [2*N-1:0] comb_req
);

    assign comb_req = {sync_req_b, sync_req_a};

endmodule

module ArbiterCore #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] req,
    output reg [WIDTH-1:0] grant
);

    reg [WIDTH-1:0] priority_mask;
    reg [WIDTH-1:0] masked_req;
    reg [WIDTH-1:0] grant_next;
    
    always @(*) begin
        priority_mask = {1'b1, {WIDTH-1{1'b0}}};
        masked_req = req & priority_mask;
        grant_next = masked_req;
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant <= 0;
        end else begin
            grant <= grant_next;
        end
    end

endmodule