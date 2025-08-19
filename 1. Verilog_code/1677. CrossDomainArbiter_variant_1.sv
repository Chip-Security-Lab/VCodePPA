//SystemVerilog
// Top level module
module CrossDomainArbiter #(parameter N=2) (
    input clk_a, clk_b, rst,
    input [N-1:0] req_a, req_b,
    output reg [N-1:0] grant
);

    wire [N-1:0] sync_a, sync_b;
    wire [2*N-1:0] comb_req;
    wire [2*N-1:0] comb_grant;

    // Instantiate synchronization modules
    SyncModule #(N) sync_a_module (
        .clk(clk_a),
        .din(req_a),
        .dout(sync_a)
    );

    CDCModule #(N) cdc_module (
        .clk_a(clk_a),
        .clk_b(clk_b),
        .din(req_b),
        .dout(sync_b)
    );

    // Combine synchronized requests
    assign comb_req = {sync_b, sync_a};

    // Instantiate arbiter core
    ArbiterCore #(2*N) arbiter_core (
        .clk(clk_a),
        .rst(rst),
        .req(comb_req),
        .grant(comb_grant)
    );

    // Grant output logic
    always @(posedge clk_a)
        grant <= comb_grant[N-1:0] | comb_grant[2*N-1:N];

endmodule

// Synchronization module for same clock domain
module SyncModule #(parameter WIDTH=2) (
    input clk,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    always @(posedge clk)
        dout <= din;
endmodule

// Clock domain crossing module
module CDCModule #(parameter WIDTH=2) (
    input clk_a, clk_b,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] meta_sync;
    
    always @(posedge clk_a) begin
        meta_sync <= din;
        dout <= meta_sync;
    end
endmodule

// Arbiter core module
module ArbiterCore #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] req,
    output reg [WIDTH-1:0] grant
);
    integer i;
    reg found;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            grant <= 0;
        else begin
            grant <= 0;
            found = 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (!found && req[i]) begin
                    grant[i] <= 1'b1;
                    found = 1;
                end
            end
        end
    end
endmodule