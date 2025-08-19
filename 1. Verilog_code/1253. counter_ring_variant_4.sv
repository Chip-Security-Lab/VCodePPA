//SystemVerilog
module counter_ring #(
    parameter DEPTH = 4
) (
    input wire clk,
    input wire rst_n,
    output reg [DEPTH-1:0] ring
);

    // Since this is a simple ring counter, the critical path is actually very short
    // However, for illustration of pipelining technique, we'll add a pipeline register
    // This would be meaningful for larger DEPTH values
    
    // First stage combinational logic
    reg [DEPTH-1:0] intermediate_ring;
    
    // Second stage registering
    reg [DEPTH-1:0] next_ring;
    
    // Split the rotation operation into two stages
    always @(*) begin
        intermediate_ring = {ring[DEPTH-2:DEPTH/2], ring[DEPTH-1], ring[DEPTH/2-1:0]};
    end
    
    // Second stage logic
    always @(*) begin
        next_ring = {intermediate_ring[DEPTH-2:0], intermediate_ring[DEPTH-1]};
    end
    
    // Sequential logic for the pipeline registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ring <= {{1'b1}, {(DEPTH-1){1'b0}}};
        else
            ring <= next_ring;
    end

endmodule