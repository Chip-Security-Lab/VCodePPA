//SystemVerilog
module signed2unsigned_unit #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0]   signed_in,
    output wire [WIDTH-1:0]   unsigned_out,
    output wire               overflow
);
    wire [WIDTH-1:0] offset;
    wire [WIDTH-1:0] abs_value;
    wire neg_flag;
    wire [WIDTH-1:0] lut_out;
    wire [WIDTH-1:0] final_result;
    
    // Generate 2^(WIDTH-1) offset (10000000 for 8-bit)
    assign offset = {1'b1, {(WIDTH-1){1'b0}}};
    
    // Sign detection
    assign neg_flag = signed_in[WIDTH-1];
    
    // LUT-based absolute value calculation
    reg [WIDTH-1:0] abs_lut [0:255];
    initial begin
        for (int i = 0; i < 256; i = i + 1) begin
            abs_lut[i] = (i[WIDTH-1]) ? (~i + 1'b1) : i;
        end
    end
    assign abs_value = abs_lut[signed_in];
    
    // LUT-based offset addition
    reg [WIDTH-1:0] add_lut [0:255];
    initial begin
        for (int i = 0; i < 256; i = i + 1) begin
            add_lut[i] = i + offset;
        end
    end
    assign lut_out = add_lut[abs_value];
    
    // Final result selection
    assign final_result = neg_flag ? lut_out : signed_in;
    assign unsigned_out = final_result;
    
    // Overflow detection
    assign overflow = neg_flag;
endmodule