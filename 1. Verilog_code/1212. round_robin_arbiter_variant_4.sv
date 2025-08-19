//SystemVerilog
module round_robin_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [WIDTH-1:0] last_grant;
    reg [WIDTH-1:0] req_reg;
    
    // Pipeline registers for critical path cutting
    reg [WIDTH-1:0] priority_mask;
    reg [WIDTH-1:0] masked_req;
    reg [WIDTH-1:0] next_grant;
    reg no_req_found;
    
    reg [$clog2(WIDTH)-1:0] grant_index;
    
    // Priority calculation logic - first pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_mask <= {WIDTH{1'b0}};
            req_reg <= {WIDTH{1'b0}};
        end else begin
            req_reg <= req_i;
            
            // Optimized priority mask calculation
            if (|last_grant) begin
                // Create mask with all 1's above the last granted bit
                priority_mask <= {WIDTH{1'b1}} << (grant_index + 1'b1);
            end else begin
                priority_mask <= {WIDTH{1'b1}};
            end
        end
    end
    
    // Grant computation logic - second pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_req <= {WIDTH{1'b0}};
            next_grant <= {WIDTH{1'b0}};
            no_req_found <= 1'b1;
        end else begin
            // Apply priority mask to requests
            masked_req <= req_reg & priority_mask;
            
            // Find first request with priority using optimized priority encoding
            if (|masked_req) begin
                // High priority requests exist
                next_grant <= masked_req & (-masked_req); // More efficient way to get lowest bit set
                no_req_found <= 1'b0;
            end else if (|req_reg) begin
                // No high priority requests, but some requests exist
                // Take the lowest bit directly
                next_grant <= req_reg & (-req_reg); // More efficient way to get lowest bit set
                no_req_found <= 1'b0;
            end else begin
                // No requests at all
                next_grant <= {WIDTH{1'b0}};
                no_req_found <= 1'b1;
            end
        end
    end
    
    // Optimized encoder for grant index calculation
    always @(*) begin
        grant_index = {$clog2(WIDTH){1'b0}};
        for (int i = 0; i < WIDTH; i++) begin
            if (next_grant[i])
                grant_index = i[$clog2(WIDTH)-1:0];
        end
    end
    
    // Output logic - third pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
            last_grant <= {WIDTH{1'b0}};
        end else begin
            grant_o <= next_grant;
            
            // Update last_grant if a request was granted
            if (!no_req_found) begin
                last_grant <= next_grant;
            end
        end
    end
endmodule