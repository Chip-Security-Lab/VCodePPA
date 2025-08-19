//SystemVerilog
module binary_gray_counter #(
    parameter WIDTH = 8,
    parameter MAX_COUNT = {WIDTH{1'b1}}
) (
    input  wire                 clock_in,
    input  wire                 reset_n,
    input  wire                 enable_in,
    input  wire                 up_down_n,
    output reg  [WIDTH-1:0]     binary_count,
    output wire [WIDTH-1:0]     gray_count,
    output wire                 terminal_count
);

    wire [WIDTH-1:0] next_binary;
    wire is_max = &binary_count;
    wire is_zero = ~|binary_count;
    
    // Optimized Gray code conversion
    assign gray_count = binary_count ^ (binary_count >> 1);
    
    // Optimized terminal count detection
    assign terminal_count = up_down_n ? is_max : is_zero;
    
    // Optimized next value calculation
    assign next_binary = up_down_n ? 
        (is_max ? {WIDTH{1'b0}} : binary_count + 1'b1) :
        (is_zero ? MAX_COUNT : binary_count - 1'b1);
    
    // Optimized counter logic
    always @(posedge clock_in or negedge reset_n) begin
        if (!reset_n)
            binary_count <= {WIDTH{1'b0}};
        else if (enable_in)
            binary_count <= next_binary;
    end

endmodule