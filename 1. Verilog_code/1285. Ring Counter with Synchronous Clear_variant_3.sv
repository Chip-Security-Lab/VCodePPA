//SystemVerilog
module clear_ring_counter(
    input wire clk,
    input wire clear, // Synchronous clear
    output reg [3:0] counter
);
    // Pipeline registers
    reg clear_d1, clear_d2;
    reg [3:0] counter_d1;
    reg [3:0] counter_next;
    
    // Initial values
    initial begin
        counter = 4'b0001;
        counter_d1 = 4'b0001;
        counter_next = 4'b0001;
        clear_d1 = 1'b0;
        clear_d2 = 1'b0;
    end
    
    // First stage: Register input signals
    always @(posedge clk) begin
        clear_d1 <= clear;
    end
    
    // Second stage: Register clear and perform computation simultaneously 
    always @(posedge clk) begin
        clear_d2 <= clear_d1;
        
        // Compute next counter value directly here (forward retiming)
        if (clear_d1)
            counter_d1 <= 4'b0000;
        else if (counter == 4'b0000)
            counter_d1 <= 4'b0001;
        else
            counter_d1 <= {counter[2:0], counter[3]};
    end
    
    // Final output stage
    always @(posedge clk) begin
        counter <= counter_d1;
    end
endmodule