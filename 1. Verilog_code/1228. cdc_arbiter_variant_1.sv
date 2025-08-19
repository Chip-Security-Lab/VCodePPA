//SystemVerilog
module cdc_arbiter #(WIDTH=4) (
    input clk_a, clk_b, rst_n,
    input [WIDTH-1:0] req_a,
    output [WIDTH-1:0] grant_b
);
    // Synchronization registers for CDC
    reg [WIDTH-1:0] sync0, sync1;
    reg [WIDTH-1:0] grant_b_reg;
    
    // Pipeline registers for critical path optimization
    reg [WIDTH-1:0] sync1_pipe;
    reg [WIDTH-1:0] priority_mask_pipe;
    
    // Signals for conditional inverse subtractor algorithm
    reg [WIDTH-1:0] operand_a, operand_b;
    reg cin;
    reg [WIDTH-1:0] sub_result;
    reg [WIDTH:0] carry;

    // Synchronize request from clk_a to clk_b domain
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            sync0 <= 0;
            sync1 <= 0;
        end else begin
            sync0 <= req_a;
            sync1 <= sync0;
        end
    end

    // First pipeline stage: store synchronized data
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            sync1_pipe <= 0;
        end else begin
            sync1_pipe <= sync1;
        end
    end

    // Second pipeline stage: calculate using conditional inverse subtractor
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            priority_mask_pipe <= 0;
        end else begin
            // Set up operands for conditional inverse subtractor
            operand_a = 0;  // Subtrahend (minuend is 0)
            operand_b = sync1_pipe;  // Subtrahend
            cin = 1'b1;  // Initial carry-in for subtraction
            
            // Conditional inverse subtractor implementation
            carry[0] = cin;
            for (int i = 0; i < WIDTH; i = i + 1) begin
                sub_result[i] = operand_a[i] ^ operand_b[i] ^ carry[i];
                carry[i+1] = (operand_a[i] & carry[i]) | 
                             (operand_a[i] & operand_b[i]) | 
                             (operand_b[i] & carry[i]);
            end
            
            priority_mask_pipe <= sub_result;
        end
    end

    // Final stage: apply mask to get grant
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            grant_b_reg <= 0;
        end else begin
            grant_b_reg <= sync1_pipe & priority_mask_pipe;
        end
    end

    assign grant_b = grant_b_reg;
endmodule