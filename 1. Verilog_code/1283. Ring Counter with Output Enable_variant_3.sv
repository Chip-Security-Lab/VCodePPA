//SystemVerilog
module output_enabled_ring_counter(
    input wire clock,
    input wire reset,
    input wire oe, // Output enable
    output wire [3:0] data
);
    // Internal signals
    reg [3:0] count;
    reg oe_reg;
    
    // Next state logic computation
    wire [3:0] next_count = {count[2:0], count[3]};
    
    // Single stage registered logic with reset
    always @(posedge clock) begin
        if (reset) begin
            count <= 4'b0001;
            oe_reg <= 1'b0;
        end
        else begin
            count <= next_count;
            oe_reg <= oe;
        end
    end
    
    // Tri-state output when registered oe is inactive
    assign data = oe_reg ? count : 4'bz;
    
endmodule