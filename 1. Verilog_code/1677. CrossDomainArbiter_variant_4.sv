//SystemVerilog
module CrossDomainArbiter #(parameter N=2) (
    input clk_a, clk_b, rst,
    input [N-1:0] req_a, req_b,
    output reg [N-1:0] grant
);

    reg [N-1:0] sync_a, sync_b;
    reg [N-1:0] meta_sync_b;
    wire [2*N-1:0] comb_req;
    wire [2*N-1:0] comb_grant;

    // Clock domain A synchronization
    always @(posedge clk_a) 
        sync_a <= req_a;

    // Clock domain B synchronization
    always @(posedge clk_a) 
        meta_sync_b <= req_b;

    always @(posedge clk_a) 
        sync_b <= meta_sync_b;

    // Request combination
    assign comb_req = {sync_b, sync_a};

    // Core arbiter instance
    ArbiterBase2 #(2*N) core (
        .clk(clk_a),
        .rst(rst),
        .req(comb_req),
        .grant(comb_grant)
    );

    // Grant output generation
    always @(posedge clk_a)
        grant <= comb_grant[N-1:0] | comb_grant[2*N-1:N];

endmodule

module ArbiterBase2 #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] req,
    output reg [WIDTH-1:0] grant
);

    reg [WIDTH-1:0] grant_next;
    reg found;
    
    // Combinational grant calculation
    always @(*) begin
        grant_next = 0;
        found = 0;
        
        for (int i = 0; i < WIDTH; i = i + 1) begin
            if (!found && req[i]) begin
                grant_next[i] = 1'b1;
                found = 1;
            end
        end
    end
    
    // Sequential grant update
    always @(posedge clk or posedge rst) begin
        if (rst)
            grant <= 0;
        else
            grant <= grant_next;
    end

endmodule