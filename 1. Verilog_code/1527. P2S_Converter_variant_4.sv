//SystemVerilog
module P2S_Converter #(parameter WIDTH=8) (
    input clk, load,
    input [WIDTH-1:0] parallel_in,
    output serial_out
);
    // Register declarations
    reg [WIDTH-1:0] buffer;
    reg [3:0] count;
    
    // Pre-computed next bit to avoid critical path through buffer indexing logic
    reg next_bit;
    
    // Output register moved before combinational logic (retiming)
    assign serial_out = next_bit;
    
    always @(posedge clk) begin
        if (load) begin
            buffer <= parallel_in;
            count <= WIDTH-1;
            // Pre-compute first bit to be output
            next_bit <= parallel_in[WIDTH-1];
        end else if (count > 0) begin
            count <= count - 1;
            // Pre-compute next bit from buffer - moved register backward
            next_bit <= buffer[count-1];
        end else begin
            // Hold last value when count reaches 0
            next_bit <= next_bit;
        end
    end
endmodule