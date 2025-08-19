module two_level_arbiter #(parameter G=2, parameter L=2) (
    input clk, rst_n,
    input [G*L-1:0] req_i,
    output [G*L-1:0] grant_o
);
    // Group request signals - OR reduction of requests within each group
    reg [G-1:0] group_req;
    // Group grant signals - which group gets to issue a grant
    reg [G-1:0] group_grant;
    // Final grant output
    reg [G*L-1:0] grant_o_reg;
    
    integer g, i, l;
    reg [31:0] idx;
    reg [31:0] rr_ptr;
    reg found;
    
    // Generate group request signals
    always @(*) begin
        for (g=0; g<G; g=g+1) begin
            group_req[g] = 0;
            for (i=0; i<L; i=i+1) begin
                group_req[g] = group_req[g] | req_i[g*L + i];
            end
        end
    end
    
    // First level: Round-robin arbitration between groups
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rr_ptr <= 0;
            group_grant <= 0;
        end else begin
            group_grant <= 0;
            found = 0;
            
            // Round robin arbitration
            for (i=0; i<G; i=i+1) begin
                idx = (rr_ptr + i) % G;
                if (group_req[idx] && !found) begin
                    group_grant[idx] <= 1'b1;
                    rr_ptr <= (idx + 1) % G;
                    found = 1;
                end
            end
        end
    end
    
    // Second level: Fixed priority arbitration within groups
    always @(*) begin
        grant_o_reg = 0;
        for (g=0; g<G; g=g+1) begin
            if (group_grant[g]) begin
                // Fixed priority within group: select lowest bit set
                for (l=0; l<L; l=l+1) begin
                    if (req_i[g*L + l] && grant_o_reg[g*L + l] == 0) begin
                        grant_o_reg[g*L + l] = 1'b1;
                    end
                end
            end
        end
    end
    
    assign grant_o = grant_o_reg;
endmodule