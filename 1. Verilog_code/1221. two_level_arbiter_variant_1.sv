//SystemVerilog
/* IEEE 1364-2005 Verilog Standard */
module two_level_arbiter #(parameter G=2, parameter L=2) (
    input clk, rst_n,
    input [G*L-1:0] req_i,
    output [G*L-1:0] grant_o
);
    // Group request signals - OR reduction of requests within each group
    wire [G-1:0] group_req;
    // Group grant signals - which group gets to issue a grant
    reg [G-1:0] group_grant;
    // Round robin pointer (state) - reduced width to minimum required
    reg [$clog2(G)-1:0] rr_ptr;
    // Final grant output
    wire [G*L-1:0] grant_o_comb;
    
    // First level: Generate group request signals (combinational)
    generate
        genvar g;
        for (g=0; g<G; g=g+1) begin : group_req_gen
            assign group_req[g] = |req_i[(g+1)*L-1:g*L];
        end
    endgenerate
    
    // First level: Combinational logic for round robin arbitration
    wire [G-1:0] group_grant_next;
    wire [$clog2(G)-1:0] rr_ptr_next;
    rr_arbiter #(.WIDTH(G)) group_arbiter (
        .req_i(group_req),
        .rr_ptr(rr_ptr),
        .grant_o(group_grant_next),
        .rr_ptr_next(rr_ptr_next)
    );
    
    // Sequential logic for group arbitration state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rr_ptr <= 0;
            group_grant <= 0;
        end else begin
            rr_ptr <= rr_ptr_next;
            group_grant <= group_grant_next;
        end
    end
    
    // Second level: Fixed priority arbitration within groups (combinational)
    fixed_priority_arbiter #(.G(G), .L(L)) local_arbiter (
        .req_i(req_i),
        .group_grant(group_grant),
        .grant_o(grant_o_comb)
    );
    
    // Assign final output
    assign grant_o = grant_o_comb;
endmodule

// Round-robin arbiter module (combinational)
module rr_arbiter #(parameter WIDTH=2) (
    input [WIDTH-1:0] req_i,
    input [$clog2(WIDTH)-1:0] rr_ptr,
    output [WIDTH-1:0] grant_o,
    output [$clog2(WIDTH)-1:0] rr_ptr_next
);
    wire [2*WIDTH-1:0] req_mask;
    wire [2*WIDTH-1:0] shifted_req;
    wire [2*WIDTH-1:0] masked_req;
    wire [WIDTH-1:0] masked_grant;
    wire [WIDTH-1:0] raw_grant;
    wire any_req;
    
    // Create a thermometer mask from priority pointer
    assign req_mask = ({WIDTH{1'b1}} << rr_ptr);
    
    // Create a wrapped request vector to handle circular priority
    assign shifted_req = {req_i, req_i};
    
    // Mask requests to implement round-robin
    assign masked_req = shifted_req & {req_mask, {WIDTH{1'b1}}};
    
    // Select first request (fixed priority) from masked requests
    // This handles requests at or above rr_ptr
    assign masked_grant = masked_req[WIDTH-1:0] | masked_req[2*WIDTH-1:WIDTH];
    
    // If no masked requests, use raw requests for fixed priority fallback
    // This handles case when no requests above rr_ptr, but requests below
    assign any_req = |req_i;
    assign raw_grant = req_i & (~(req_i - 1));  // Get least significant bit set
    
    // Select between masked and raw grants based on presence of masked requests
    assign grant_o = |masked_grant ? (masked_grant & (~(masked_grant - 1))) : raw_grant;
    
    // Update round-robin pointer based on current grant
    // Find position of granted bit for next pointer
    wire [$clog2(WIDTH)-1:0] grant_pos;
    integer i;
    
    // Priority encoder to get position of grant
    reg [$clog2(WIDTH)-1:0] pos_encoder;
    always @(*) begin
        pos_encoder = 0;
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (grant_o[i]) pos_encoder = i[$clog2(WIDTH)-1:0];
        end
    end
    
    assign grant_pos = pos_encoder;
    assign rr_ptr_next = any_req ? ((grant_pos + 1) % WIDTH) : rr_ptr;
endmodule

// Fixed-priority arbiter module (combinational)
module fixed_priority_arbiter #(parameter G=2, parameter L=2) (
    input [G*L-1:0] req_i,
    input [G-1:0] group_grant,
    output [G*L-1:0] grant_o
);
    wire [G*L-1:0] masked_req;
    wire [G*L-1:0] one_hot_grants;
    
    // Generate a mask for each group's requests based on group_grant
    generate
        genvar g;
        for (g = 0; g < G; g = g + 1) begin : mask_gen
            assign masked_req[(g+1)*L-1:g*L] = group_grant[g] ? req_i[(g+1)*L-1:g*L] : {L{1'b0}};
        end
    endgenerate
    
    // Find the lowest bit set in each group using the "isolate rightmost 1" technique
    assign one_hot_grants = masked_req & (~masked_req + 1);
    
    // Final grant output
    assign grant_o = one_hot_grants;
endmodule