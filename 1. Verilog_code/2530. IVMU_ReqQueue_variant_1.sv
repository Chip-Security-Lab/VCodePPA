//SystemVerilog
module IVMU_ReqQueue #(parameter DEPTH=4) (
    input clk, rd_en,
    input [7:0] irq,
    output reg [7:0] next_irq
);
    reg [7:0] queue [0:DEPTH-1];
    integer i;

    always @(posedge clk) begin
        // Update queue elements using conditional operators
        // Based on rd_en and index i, determine the source for the next state of queue[i]
        // If rd_en is high: shift elements left (queue[i] gets queue[i+1]) and clear the last element (queue[DEPTH-1] gets 0)
        // If rd_en is low: shift elements right (queue[i] gets queue[i-1]) and insert new irq at the front (queue[0] gets irq)
        for (i = 0; i < DEPTH; i = i + 1) begin
            queue[i] <= rd_en ?
                        ( (i < DEPTH - 1) ? queue[i+1] : 8'h0 ) : // Logic when rd_en is high
                        ( (i == 0) ? irq : queue[i-1] );         // Logic when rd_en is low
        end

        // next_irq should reflect the value queue[0] will have after the clock edge.
        // This value is determined by the conditional expression for i=0.
        // The expression for queue[0] simplifies to:
        // rd_en ? ( (0 < DEPTH - 1) ? queue[1] : 8'h0 ) : ( (0 == 0) ? irq : queue[-1] )
        // which is: rd_en ? ( (DEPTH > 1) ? queue[1] : 8'h0 ) : irq
        next_irq <= rd_en ? ( (DEPTH > 1) ? queue[1] : 8'h0 ) : irq;
    end
endmodule