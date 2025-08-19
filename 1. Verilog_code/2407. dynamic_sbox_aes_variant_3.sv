//SystemVerilog
module dynamic_sbox_aes (
    input  wire        clk,       // Clock signal
    input  wire        gen_sbox,  // Control signal to generate S-box
    input  wire [7:0]  sbox_in,   // Input byte for S-box lookup
    output reg  [7:0]  sbox_out   // S-box transformation output
);
    // S-box memory and pipeline registers
    reg [7:0] sbox_memory [0:255];    // S-box lookup table
    reg [7:0] sbox_in_reg;            // Input data register
    reg [7:0] transform_value;        // Intermediate transformation value
    reg       sbox_generated;         // Flag indicating S-box is generated
    
    // S-box generation control logic
    reg gen_sbox_reg;
    reg generation_active;
    
    // S-box generation counter
    reg [7:0] gen_counter;
    
    // Generation stage - First pipeline stage
    always @(posedge clk) begin
        gen_sbox_reg <= gen_sbox;
        
        // Detect rising edge of gen_sbox to start generation
        if (gen_sbox && !gen_sbox_reg) begin
            generation_active <= 1'b1;
            gen_counter <= 8'd0;
        end
        
        // S-box generation state machine
        if (generation_active) begin
            // Calculate and store transformation for current index
            transform_value <= (gen_counter * 8'h1B) ^ 8'h63;
            
            // Increment counter and check if generation is complete
            if (gen_counter == 8'd255) begin
                generation_active <= 1'b0;
                sbox_generated <= 1'b1;
            end else begin
                gen_counter <= gen_counter + 8'd1;
            end
        end
    end
    
    // Memory update stage - Second pipeline stage
    always @(posedge clk) begin
        // Register input for lookup pipeline
        sbox_in_reg <= sbox_in;
        
        // Update S-box memory when generation is active
        if (generation_active) begin
            sbox_memory[gen_counter] <= transform_value;
        end
    end
    
    // Lookup stage - Final pipeline stage
    always @(posedge clk) begin
        // Only perform lookup when S-box is generated
        if (sbox_generated) begin
            sbox_out <= sbox_memory[sbox_in_reg];
        end else begin
            sbox_out <= 8'h00; // Default output when S-box not yet generated
        end
    end
    
endmodule