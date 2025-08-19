//SystemVerilog
module wave8_ramp_down #(
    parameter WIDTH = 8,
    parameter STEP  = 1
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    // Internal signals for carry look-ahead subtractor
    wire [WIDTH-1:0] subtrahend;
    wire [WIDTH-1:0] diff;
    wire [WIDTH:0] borrow;
    
    // Generate signals
    wire [WIDTH-1:0] gen;
    wire [WIDTH-1:0] prop;
    
    // Fixed subtrahend (STEP)
    assign subtrahend = STEP[WIDTH-1:0];
    
    // Generate and propagate signals
    assign gen = ~wave_out & subtrahend;
    assign prop = wave_out | subtrahend;
    
    // Calculate borrows using look-ahead logic
    assign borrow[0] = 1'b0; // No initial borrow
    
    // While loop implementation for borrow calculation
    generate
        // Initialization
        integer i;
        wire [WIDTH:0] temp_borrow;
        
        // Start with initialization
        assign temp_borrow[0] = 1'b0;
        
        // Unrolled loop equivalent to while loop
        // i = 0 condition is handled by initialization
        // Loop body and iteration are combined
        assign temp_borrow[1] = gen[0] | (prop[0] & temp_borrow[0]);
        assign temp_borrow[2] = gen[1] | (prop[1] & temp_borrow[1]);
        assign temp_borrow[3] = gen[2] | (prop[2] & temp_borrow[2]);
        assign temp_borrow[4] = gen[3] | (prop[3] & temp_borrow[3]);
        assign temp_borrow[5] = gen[4] | (prop[4] & temp_borrow[4]);
        assign temp_borrow[6] = gen[5] | (prop[5] & temp_borrow[5]);
        assign temp_borrow[7] = gen[6] | (prop[6] & temp_borrow[6]);
        assign temp_borrow[8] = gen[7] | (prop[7] & temp_borrow[7]);
        
        // Connect to output borrow signal
        assign borrow = temp_borrow;
    endgenerate
    
    // Calculate difference
    assign diff = wave_out ^ subtrahend ^ borrow[WIDTH-1:0];
    
    // Register the output
    always @(posedge clk) begin
        wave_out <= rst ? {WIDTH{1'b1}} : diff;
    end
endmodule