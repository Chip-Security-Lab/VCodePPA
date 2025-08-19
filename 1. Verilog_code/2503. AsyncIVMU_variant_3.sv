//SystemVerilog
module AsyncIVMU (
    input [7:0] int_lines,
    input [7:0] int_mask,
    output [31:0] vector_out,
    output int_active
);
    // Memory array for interrupt vectors
    reg [31:0] vector_map [0:7];
    
    // Masked interrupts
    wire [7:0] masked_ints;
    
    // Index of the highest priority active interrupt
    reg [2:0] active_int;
    
    // Loop variable for initialization
    integer i;
    
    // Initialize interrupt vector map
    // This is typically done in an initial block for simulation
    // or synthesized into memory initialization data
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            vector_map[i] = 32'h2000_0000 + (i * 4);
        end
    end
    
    // Apply interrupt mask
    assign masked_ints = int_lines & ~int_mask;
    
    // Indicate if any interrupt is active after masking
    assign int_active = |masked_ints;
    
    // Priority encoder: Find the highest priority active interrupt
    // Replaced loop with explicit priority logic for better synthesis
    always @(*) begin
        // Default value when no interrupts are active
        active_int = 3'b000; 
        
        // Check for the highest priority interrupt first (bit 7)
        if (masked_ints[7]) begin
            active_int = 3'b111; // Index 7
        end else if (masked_ints[6]) begin
            active_int = 3'b110; // Index 6
        end else if (masked_ints[5]) begin
            active_int = 3'b101; // Index 5
        end else if (masked_ints[4]) begin
            active_int = 3'b100; // Index 4
        end else if (masked_ints[3]) begin
            active_int = 3'b011; // Index 3
        end else if (masked_ints[2]) begin
            active_int = 3'b010; // Index 2
        end else if (masked_ints[1]) begin
            active_int = 3'b001; // Index 1
        end else if (masked_ints[0]) begin
            active_int = 3'b000; // Index 0 (lowest priority)
        end
        // If no bits are set, active_int remains 0 from the default assignment.
    end
    
    // Output the vector corresponding to the active interrupt
    // If no interrupt is active (active_int is 0), vector_map[0] is output.
    assign vector_out = vector_map[active_int];
    
endmodule