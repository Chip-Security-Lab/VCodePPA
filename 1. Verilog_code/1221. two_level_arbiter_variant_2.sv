//SystemVerilog
//=====================================================================
//=====================================================================

//=====================================================================
// Top-level module: two_level_arbiter
//=====================================================================
module two_level_arbiter #(
    parameter G = 2,  // Number of groups
    parameter L = 2   // Number of requesters per group
) (
    input  wire        clk,      // System clock
    input  wire        rst_n,    // Active-low reset
    input  wire [G*L-1:0] req_i,   // Request inputs
    output wire [G*L-1:0] grant_o  // Grant outputs
);

    // Internal signals
    wire [G-1:0] group_req;        // Group request signals
    wire [G-1:0] group_grant;      // Group grant signals

    // Instantiate group request generator
    group_request_gen #(
        .G(G),
        .L(L)
    ) u_group_request_gen (
        .req_i(req_i),
        .group_req_o(group_req)
    );

    // Instantiate round-robin arbiter for groups
    group_rr_arbiter #(
        .G(G)
    ) u_group_rr_arbiter (
        .clk(clk),
        .rst_n(rst_n),
        .group_req_i(group_req),
        .group_grant_o(group_grant)
    );

    // Instantiate fixed-priority arbiter for within groups
    local_fixed_priority_arbiter #(
        .G(G),
        .L(L)
    ) u_local_fixed_priority_arbiter (
        .req_i(req_i),
        .group_grant_i(group_grant),
        .grant_o(grant_o)
    );

endmodule

//=====================================================================
// Module: group_request_gen
// Purpose: Generate group request signals by OR-ing requests within each group
//=====================================================================
module group_request_gen #(
    parameter G = 2,  // Number of groups
    parameter L = 2   // Number of requesters per group
) (
    input  wire [G*L-1:0] req_i,      // Request inputs
    output wire [G-1:0]   group_req_o // Group request outputs
);

    genvar g;
    generate
        for (g = 0; g < G; g = g + 1) begin : gen_group_req
            assign group_req_o[g] = |req_i[g*L+:L];
        end
    endgenerate

endmodule

//=====================================================================
// Module: group_rr_arbiter
// Purpose: Round-robin arbitration between groups
//=====================================================================
module group_rr_arbiter #(
    parameter G = 2  // Number of groups
) (
    input  wire        clk,            // System clock
    input  wire        rst_n,          // Active-low reset
    input  wire [G-1:0] group_req_i,   // Group request inputs
    output reg  [G-1:0] group_grant_o  // Group grant outputs
);

    reg [$clog2(G)-1:0] rr_ptr;  // Round-robin pointer with minimum width
    wire [2*G-1:0] double_req;   // Double the request vector for easier circular priority
    wire [2*G-1:0] double_grant; // Double the grant output for circular priority
    wire [G-1:0] masked_req;     // Requests at and above current priority
    wire [G-1:0] masked_grant;   // Grants for masked requests
    wire [G-1:0] unmasked_req;   // Requests below current priority
    wire [G-1:0] unmasked_grant; // Grants for unmasked requests
    wire no_masked_req;          // Flag indicating no masked requests
    
    // Assign double request vector for wrap-around
    assign double_req = {group_req_i, group_req_i};
    
    // Create masked request vector - requests at and above current priority
    assign masked_req = double_req[rr_ptr+:G] & group_req_i;
    
    // Create unmasked request vector - requests below current priority
    assign unmasked_req = group_req_i;
    
    // Priority arbitration for masked requests - find first request
    assign masked_grant = masked_req & (~masked_req + 1);
    
    // Priority arbitration for unmasked requests - find first request
    assign unmasked_grant = unmasked_req & (~unmasked_req + 1);
    
    // Check if there are any masked requests
    assign no_masked_req = (masked_req == 0);
    
    // Select appropriate grant vector
    always @(*) begin
        if (no_masked_req && |group_req_i)
            group_grant_o = unmasked_grant; // Grant to highest priority below rr_ptr
        else
            group_grant_o = masked_grant;   // Grant to highest priority at or above rr_ptr
    end
    
    // Update round-robin pointer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rr_ptr <= 0;
        end else if (|group_grant_o) begin
            // Find position of grant and set pointer to the next position
            for (int i = 0; i < G; i++) begin
                if (group_grant_o[i])
                    rr_ptr <= (i + 1) % G;
            end
        end
    end

endmodule

//=====================================================================
// Module: local_fixed_priority_arbiter
// Purpose: Fixed priority arbitration within groups
//=====================================================================
module local_fixed_priority_arbiter #(
    parameter G = 2,  // Number of groups
    parameter L = 2   // Number of requesters per group
) (
    input  wire [G*L-1:0] req_i,         // Request inputs
    input  wire [G-1:0]   group_grant_i, // Group grant inputs
    output wire [G*L-1:0] grant_o        // Grant outputs
);

    wire [G*L-1:0] group_mask;  // Mask for each group based on group_grant_i
    wire [G*L-1:0] masked_req;  // Requests masked by group selection
    
    genvar g, l;
    generate
        // Generate group masks from group_grant_i
        for (g = 0; g < G; g = g + 1) begin : gen_group_mask
            for (l = 0; l < L; l = l + 1) begin : gen_local_mask
                assign group_mask[g*L + l] = group_grant_i[g];
            end
        end
        
        // Apply group mask to requests
        assign masked_req = req_i & group_mask;
        
        // Fixed priority arbiter for each group
        for (g = 0; g < G; g = g + 1) begin : gen_group_arbiter
            wire [L-1:0] local_req = masked_req[g*L+:L];
            wire [L-1:0] local_grant = local_req & (~local_req + 1);
            
            // Assign to output
            for (l = 0; l < L; l = l + 1) begin : assign_grant
                assign grant_o[g*L + l] = local_grant[l];
            end
        end
    endgenerate

endmodule