//SystemVerilog
module RangeDetector_AddrConfig #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk, rst_n,
    input [DATA_WIDTH-1:0] data_in,
    input [ADDR_WIDTH-1:0] addr,
    output reg out_of_range
);
    reg [DATA_WIDTH-1:0] lower_bounds [2**ADDR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] upper_bounds [2**ADDR_WIDTH-1:0];
    
    // Pipeline Stage 1: Register input data and address
    reg [DATA_WIDTH-1:0] data_in_stage1;
    reg [ADDR_WIDTH-1:0] addr_stage1;
    
    // Pipeline Stage 2: Fetch bounds from memory
    reg [DATA_WIDTH-1:0] lower_bound_stage2;
    reg [DATA_WIDTH-1:0] upper_bound_stage2;
    reg [DATA_WIDTH-1:0] data_in_stage2;
    
    // Pipeline Stage 3: Perform comparisons using carry-lookahead subtractor
    reg lower_compare_stage3;
    reg upper_compare_stage3;
    
    // Carry-lookahead subtractor signals
    wire [DATA_WIDTH-1:0] lower_diff;
    wire [DATA_WIDTH-1:0] upper_diff;
    wire lower_borrow;
    wire upper_borrow;
    
    // Carry-lookahead subtractor for lower bound comparison
    assign lower_diff = data_in_stage2 ^ lower_bound_stage2;
    assign lower_borrow = ~data_in_stage2 & lower_bound_stage2;
    
    // Carry-lookahead subtractor for upper bound comparison
    assign upper_diff = upper_bound_stage2 ^ data_in_stage2;
    assign upper_borrow = ~upper_bound_stage2 & data_in_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 0;
            addr_stage1 <= 0;
            lower_bound_stage2 <= 0;
            upper_bound_stage2 <= 0;
            data_in_stage2 <= 0;
            lower_compare_stage3 <= 0;
            upper_compare_stage3 <= 0;
            out_of_range <= 0;
        end else begin
            // Stage 1: Register inputs
            data_in_stage1 <= data_in;
            addr_stage1 <= addr;
            
            // Stage 2: Memory lookup and data forwarding
            lower_bound_stage2 <= lower_bounds[addr_stage1];
            upper_bound_stage2 <= upper_bounds[addr_stage1];
            data_in_stage2 <= data_in_stage1;
            
            // Stage 3: Perform comparisons using carry-lookahead results
            lower_compare_stage3 <= lower_borrow;
            upper_compare_stage3 <= upper_borrow;
            
            // Stage 4: Final result calculation
            out_of_range <= lower_compare_stage3 || upper_compare_stage3;
        end
    end
endmodule