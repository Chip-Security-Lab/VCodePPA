//SystemVerilog
module dynamic_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input [WIDTH-1:0] pri_map,  // External priority
    output reg [WIDTH-1:0] grant_o
);
    // Stage 1: Generate masked request
    reg [WIDTH-1:0] masked_req_stage1;
    
    // Stage 2: Priority detection
    reg [WIDTH-1:0] priority_match_stage2;
    reg [$clog2(WIDTH):0] priority_index_stage2;
    reg valid_req_stage2;
    
    // Borrow-based subtraction signals
    reg [WIDTH:0] borrow;
    reg [WIDTH-1:0] subtraction_result;
    
    // Stage 1: Mask requests with priority map
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_req_stage1 <= 0;
        end else begin
            masked_req_stage1 <= req_i & pri_map;
        end
    end
    
    // Stage 2: Priority detection using borrow-based algorithm
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_match_stage2 <= 0;
            priority_index_stage2 <= 0;
            valid_req_stage2 <= 0;
            borrow <= 0;
            subtraction_result <= 0;
        end else begin
            valid_req_stage2 <= |masked_req_stage1;
            priority_match_stage2 <= 0;
            
            // Initialize borrow
            borrow[0] <= 0;
            
            // Borrow-based priority detection
            for (i = 0; i < WIDTH; i = i + 1) begin
                // Calculate each bit of subtraction result and propagate borrow
                // Using borrow subtraction where '1' results from matched request
                subtraction_result[i] <= masked_req_stage1[i] ^ borrow[i];
                borrow[i+1] <= (~masked_req_stage1[i] & borrow[i]);
                
                // Detect the highest priority (rightmost '1')
                if (masked_req_stage1[i] && ~borrow[i]) begin
                    priority_match_stage2[i] <= 1'b1;
                    priority_index_stage2 <= i;
                end
            end
        end
    end
    
    // Stage 3: Generate final grant output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= 0;
        end else begin
            grant_o <= valid_req_stage2 ? (1'b1 << priority_index_stage2) : 0;
        end
    end
    
endmodule