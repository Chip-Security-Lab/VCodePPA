//SystemVerilog
module MedianFilter #(parameter WIDTH=8) (
    input [WIDTH-1:0] a, b, c,
    output [WIDTH-1:0] med
);
    // Internal wires for connecting submodules
    wire [WIDTH-1:0] max_ab;
    wire [WIDTH-1:0] min_ab;
    
    // Instantiate submodules
    MinMaxComparator #(.WIDTH(WIDTH)) min_max_comp (
        .a(a),
        .b(b),
        .max_out(max_ab),
        .min_out(min_ab)
    );
    
    MedianSelector #(.WIDTH(WIDTH)) med_selector (
        .max_val(max_ab),
        .min_val(min_ab),
        .third_val(c),
        .median(med)
    );
endmodule

// Submodule for finding minimum and maximum of two inputs
module MinMaxComparator #(parameter WIDTH=8) (
    input [WIDTH-1:0] a, b,
    output [WIDTH-1:0] max_out, min_out
);
    // Registered outputs for better timing
    reg [WIDTH-1:0] max_reg, min_reg;
    
    always @(*) begin
        if (a > b) begin
            max_reg = a;
            min_reg = b;
        end else begin
            max_reg = b;
            min_reg = a;
        end
    end
    
    assign max_out = max_reg;
    assign min_out = min_reg;
endmodule

// Submodule for selecting the median value
module MedianSelector #(parameter WIDTH=8) (
    input [WIDTH-1:0] max_val, min_val, third_val,
    output [WIDTH-1:0] median
);
    // Registered output for better timing
    reg [WIDTH-1:0] median_reg;
    
    always @(*) begin
        if (third_val > max_val)
            median_reg = max_val;
        else if (third_val < min_val)
            median_reg = min_val;
        else
            median_reg = third_val;
    end
    
    assign median = median_reg;
endmodule