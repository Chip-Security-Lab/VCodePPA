//SystemVerilog
module clock_gated_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n, enable,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out
);
    // Clock gating cell (simplified for synthesis)
    wire gated_clk;
    reg enable_latch;
    
    always @(clk or enable)
        if (!clk) enable_latch <= enable;
        
    assign gated_clk = clk & enable_latch;
    
    // Pipeline registers for critical path optimization
    reg [WIDTH-1:0] data_in_reg;
    reg [WIDTH/2-1:0] upper_half_valid;
    reg [$clog2(WIDTH)-1:0] upper_priority, lower_priority;
    reg upper_half_has_one;
    
    // First pipeline stage: Register inputs and perform initial processing
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 0;
            upper_half_valid <= 0;
            upper_half_has_one <= 0;
        end else begin
            data_in_reg <= data_in;
            // Check if upper half has any 1's (pre-compute)
            upper_half_valid <= data_in[WIDTH-1:WIDTH/2];
            upper_half_has_one <= |data_in[WIDTH-1:WIDTH/2];
        end
    end
    
    // Second pipeline stage: Compute priorities for upper and lower halves in parallel
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            upper_priority <= 0;
            lower_priority <= 0;
        end else begin
            // Upper half priority logic
            upper_priority <= 0;
            for (integer i = WIDTH-1; i >= WIDTH/2; i = i - 1)
                if (data_in_reg[i]) upper_priority <= i[$clog2(WIDTH)-1:0];
                
            // Lower half priority logic
            lower_priority <= 0;
            for (integer i = WIDTH/2-1; i >= 0; i = i - 1)
                if (data_in_reg[i]) lower_priority <= i[$clog2(WIDTH)-1:0];
        end
    end
    
    // Final stage: Select between upper and lower half priorities
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
        end else begin
            priority_out <= upper_half_has_one ? upper_priority : lower_priority;
        end
    end
endmodule