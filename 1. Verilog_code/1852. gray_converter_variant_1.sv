//SystemVerilog
module gray_converter #(parameter WIDTH=4) (
    input [WIDTH-1:0] bin_in,
    input bin_to_gray,
    output reg [WIDTH-1:0] result
);
    integer i;
    
    always @(*) begin
        // Convert bin-to-gray or gray-to-bin using conditional operator
        result[WIDTH-1] = bin_to_gray ? bin_in[WIDTH-1] ^ bin_in[WIDTH-2] : bin_in[WIDTH-1];
        
        // Handle the remaining bits
        for(i=WIDTH-2; i>=0; i=i-1) begin
            result[i] = bin_to_gray ? 
                        // Bin to Gray: XOR with next higher bit
                        (i > 0 ? bin_in[i] ^ bin_in[i-1] : bin_in[0]) : 
                        // Gray to Bin: XOR with already converted higher bit
                        bin_in[i] ^ result[i+1];
        end
    end
endmodule