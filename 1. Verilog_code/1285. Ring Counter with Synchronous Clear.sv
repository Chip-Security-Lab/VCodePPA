module clear_ring_counter(
    input wire clk,
    input wire clear, // Synchronous clear
    output reg [3:0] counter
);
    initial counter = 4'b0001;
    
    always @(posedge clk) begin
        if (clear)
            counter <= 4'b0000; // All zeros
        else if (counter == 4'b0000)
            counter <= 4'b0001; // Recover from clear
        else
            counter <= {counter[2:0], counter[3]};
    end
endmodule