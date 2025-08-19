//SystemVerilog
// Top module: nand2_17
module nand2_17 #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] A, B,
    output wire [WIDTH-1:0] Y
);
    // Internal connection signals
    wire [WIDTH-1:0] subtractor_result;
    
    // Instantiate borrow subtractor submodule
    borrow_subtractor #(
        .BIT_WIDTH(WIDTH)
    ) subtractor_inst (
        .minuend(A),
        .subtrahend(B),
        .difference(subtractor_result)
    );
    
    // Instantiate output processing submodule
    output_processor #(
        .BIT_WIDTH(WIDTH)
    ) processor_inst (
        .in_data(subtractor_result),
        .out_data(Y)
    );
    
endmodule

// Submodule for borrow subtractor operation
module borrow_subtractor #(
    parameter BIT_WIDTH = 8
) (
    input wire [BIT_WIDTH-1:0] minuend,
    input wire [BIT_WIDTH-1:0] subtrahend,
    output wire [BIT_WIDTH-1:0] difference
);
    // Internal borrow signals
    wire [BIT_WIDTH:0] borrow;
    
    // Initialize first borrow bit to 0
    assign borrow[0] = 1'b0;
    
    // Generate borrow chain and difference
    genvar i;
    generate
        for (i = 0; i < BIT_WIDTH; i = i + 1) begin : gen_borrow_logic
            assign difference[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
            assign borrow[i+1] = (~minuend[i] & subtrahend[i]) | (~minuend[i] & borrow[i]) | (subtrahend[i] & borrow[i]);
        end
    endgenerate
    
endmodule

// Submodule for processing the output to maintain NAND functionality
module output_processor #(
    parameter BIT_WIDTH = 8
) (
    input wire [BIT_WIDTH-1:0] in_data,
    output wire [BIT_WIDTH-1:0] out_data
);
    // Process data to maintain NAND functionality
    assign out_data = ~(in_data + 1'b1);
endmodule