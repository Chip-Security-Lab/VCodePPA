module output_enabled_ring_counter(
    input wire clock,
    input wire reset,
    input wire oe, // Output enable
    output wire [3:0] data
);
    reg [3:0] count;
    
    // Tri-state output when oe is inactive
    assign data = oe ? count : 4'bz;
    
    always @(posedge clock) begin
        if (reset)
            count <= 4'b0001;
        else
            count <= {count[2:0], count[3]};
    end
endmodule