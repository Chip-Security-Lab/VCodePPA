//SystemVerilog
module free_counter #(parameter MAX = 255) (
    input wire clk,
    output reg [7:0] count,
    output reg tc
);
    // Pipeline stage registers
    reg [7:0] count_stage1;
    reg [7:0] count_stage2;
    reg [7:0] next_count;
    reg tc_stage1;
    
    // Stage 1: Calculate next count value
    always @(*) begin
        next_count = (count_stage2 == MAX) ? 8'd0 : count_stage2 + 1'b1;
    end
    
    // Pipeline registers update
    always @(posedge clk) begin
        // Stage 1: Store intermediate calculation
        count_stage1 <= next_count;
        tc_stage1 <= (next_count == MAX);
        
        // Stage 2: Update final outputs
        count_stage2 <= count_stage1;
        count <= count_stage2;
        tc <= tc_stage1;
    end
endmodule