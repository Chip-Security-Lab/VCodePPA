module CrossDomainArbiter #(parameter N=2) (
    input clk_a, clk_b, rst,
    input [N-1:0] req_a, req_b,
    output reg [N-1:0] grant
);
reg [N-1:0] sync_a, sync_b;
reg [N-1:0] meta_sync_b;

// Synchronize req_a to clk_a domain
always @(posedge clk_a) 
    sync_a <= req_a;

// CDC: Two-stage synchronizer for req_b to clk_a domain
always @(posedge clk_a) begin
    meta_sync_b <= req_b;
    sync_b <= meta_sync_b;
end

wire [2*N-1:0] comb_req = {sync_b, sync_a};
wire [2*N-1:0] comb_grant;

ArbiterBase2 #(2*N) core (
    .clk(clk_a), .rst(rst),
    .req(comb_req),
    .grant(comb_grant)
);

always @(posedge clk_a)
    grant <= comb_grant[N-1:0] | comb_grant[2*N-1:N];
endmodule

module ArbiterBase2 #(parameter WIDTH=4) (
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