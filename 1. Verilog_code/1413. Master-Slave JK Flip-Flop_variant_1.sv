//SystemVerilog
module ms_jk_flip_flop (
    input wire clk,
    input wire j,
    input wire k,
    output wire q
);
    reg next_master;
    reg slave;
    
    // Pre-compute next state logic outside the clock edge
    // Case structure converted to if-else cascade
    always @(*) begin
        if ({j, k} == 2'b00)
            next_master = slave;  // No change
        else if ({j, k} == 2'b01)
            next_master = 1'b0;   // Reset
        else if ({j, k} == 2'b10)
            next_master = 1'b1;   // Set
        else // {j, k} == 2'b11
            next_master = ~slave; // Toggle
    end
    
    // Register the slave value at clock edges
    always @(negedge clk) begin
        slave <= next_master;
    end
    
    assign q = slave;
endmodule