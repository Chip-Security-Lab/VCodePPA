//SystemVerilog
// SystemVerilog
//***************************************************************************
// Module: level_async_ismu
// Description: Top-level interrupt service management unit with level-sensitive
//              asynchronous interrupts - optimized implementation with LUT-based
//              subtraction algorithm
// Standard: IEEE 1364-2005
//***************************************************************************
module level_async_ismu #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] irq_in,     // Interrupt request inputs
    input  [WIDTH-1:0] mask,       // Interrupt mask bits (1=masked)
    input  clear_n,                // Clear signal (active low)
    output [WIDTH-1:0] active_irq, // Active interrupt outputs
    output irq_present             // Interrupt present indicator
);
    // Implement masking using LUT-based subtraction algorithm
    wire [WIDTH-1:0] inv_mask;     // Inverted mask
    wire [WIDTH-1:0] subtracted_result;
    
    // Invert mask for subtraction operation
    assign inv_mask = ~mask;
    
    // Instantiate LUT-based subtractor
    lut_subtractor #(
        .WIDTH(WIDTH)
    ) mask_subtractor (
        .minuend(irq_in),
        .subtrahend(inv_mask),
        .borrow_in(1'b0),
        .difference(subtracted_result)
    );
    
    // Apply clear signal 
    assign active_irq = subtracted_result & {WIDTH{clear_n}};
    
    // Fast interrupt presence detection using reduction OR
    assign irq_present = |active_irq;
    
endmodule

//***************************************************************************
// Module: lut_subtractor
// Description: Implements 8-bit subtraction using lookup table approach
// Standard: IEEE 1364-2005
//***************************************************************************
module lut_subtractor #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] minuend,      // Number to subtract from
    input  [WIDTH-1:0] subtrahend,   // Number to subtract
    input  borrow_in,                // Input borrow
    output [WIDTH-1:0] difference    // Subtraction result
);
    // Internal signals
    reg [WIDTH-1:0] diff_lut;
    reg [WIDTH:0] borrow_chain;
    
    // Initialize borrow chain with input borrow
    always @(*) begin
        borrow_chain[0] = borrow_in;
        
        // Process each bit position with lookup-based subtraction
        for (integer i = 0; i < WIDTH; i = i + 1) begin
            // Subtraction truth table implementation
            case ({minuend[i], subtrahend[i], borrow_chain[i]})
                3'b000: begin diff_lut[i] = 1'b0; borrow_chain[i+1] = 1'b0; end
                3'b001: begin diff_lut[i] = 1'b1; borrow_chain[i+1] = 1'b1; end
                3'b010: begin diff_lut[i] = 1'b1; borrow_chain[i+1] = 1'b1; end
                3'b011: begin diff_lut[i] = 1'b0; borrow_chain[i+1] = 1'b1; end
                3'b100: begin diff_lut[i] = 1'b1; borrow_chain[i+1] = 1'b0; end
                3'b101: begin diff_lut[i] = 1'b0; borrow_chain[i+1] = 1'b0; end
                3'b110: begin diff_lut[i] = 1'b0; borrow_chain[i+1] = 1'b0; end
                3'b111: begin diff_lut[i] = 1'b1; borrow_chain[i+1] = 1'b1; end
            endcase
        end
    end
    
    // Assign output difference
    assign difference = diff_lut;
    
endmodule

//***************************************************************************
// Module: irq_mask_unit
// Description: Handles masking of input interrupts using LUT-based subtraction
// Standard: IEEE 1364-2005
//***************************************************************************
module irq_mask_unit #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] irq_in,     // Interrupt request inputs
    input  [WIDTH-1:0] mask,       // Interrupt mask bits (1=masked)
    output [WIDTH-1:0] masked_irq  // Masked interrupt outputs
);
    wire [WIDTH-1:0] inv_mask;
    
    // Invert mask for the subtraction operation
    assign inv_mask = ~mask;
    
    // Use LUT-based subtractor
    lut_subtractor #(
        .WIDTH(WIDTH)
    ) mask_subtractor (
        .minuend(irq_in),
        .subtrahend(inv_mask),
        .borrow_in(1'b0),
        .difference(masked_irq)
    );
    
endmodule

//***************************************************************************
// Module: irq_clear_unit
// Description: Controls clearing of active interrupts
// Standard: IEEE 1364-2005
//***************************************************************************
module irq_clear_unit #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] masked_irq, // Masked interrupt inputs
    input  clear_n,                // Clear signal (active low)
    output [WIDTH-1:0] active_irq  // Active interrupt outputs
);
    
    // Gate all interrupts with clear signal
    assign active_irq = masked_irq & {WIDTH{clear_n}};
    
endmodule

//***************************************************************************
// Module: irq_detect_unit
// Description: Detects presence of any active interrupt
// Standard: IEEE 1364-2005
//***************************************************************************
module irq_detect_unit #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] active_irq, // Active interrupt inputs
    output irq_present            // Interrupt present indicator
);
    
    // Assert irq_present if any bit in active_irq is high
    assign irq_present = |active_irq;
    
endmodule