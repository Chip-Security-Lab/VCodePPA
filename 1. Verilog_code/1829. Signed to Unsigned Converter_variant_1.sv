//SystemVerilog
module signed2unsigned_unit #(
    parameter WIDTH = 8
)(
    input  wire                 clk,           // Clock signal for pipeline registers
    input  wire                 rst_n,         // Active-low reset
    input  wire [WIDTH-1:0]     signed_in,     // Signed input data
    output wire [WIDTH-1:0]     unsigned_out,  // Unsigned output data
    output wire                 overflow       // Overflow flag
);
    // Stage 1: Input registration with optimized sign detection
    reg [WIDTH-1:0] signed_in_reg;
    reg             sign_bit_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signed_in_reg <= '0;
            sign_bit_reg <= 1'b0;
        end else begin
            signed_in_reg <= signed_in;
            sign_bit_reg <= signed_in[WIDTH-1];  // Extract sign bit
        end
    end
    
    // Stage 2: Optimized conversion pipeline
    reg [WIDTH-1:0] conversion_result;
    reg             overflow_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            conversion_result <= '0;
            overflow_reg <= 1'b0;
        end else begin
            // Optimized conversion: toggle MSB for 2's complement conversion
            conversion_result <= {~signed_in_reg[WIDTH-1], signed_in_reg[WIDTH-2:0]};
            overflow_reg <= sign_bit_reg;
        end
    end
    
    // Output assignment with registered outputs for improved timing
    assign unsigned_out = conversion_result;
    assign overflow = overflow_reg;

endmodule