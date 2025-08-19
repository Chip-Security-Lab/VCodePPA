//SystemVerilog
module sync_arithmetic_right_shifter #(
    parameter DW = 32,  // Data width
    parameter SW = 5    // Shift width
)(
    input                  clk_i,
    input                  en_i,
    input      [DW-1:0]    data_i,
    input      [SW-1:0]    shift_i,
    output reg [DW-1:0]    data_o
);
    // Internal signals for the 8-bit look-ahead borrow subtractor
    wire [7:0] minuend, subtrahend, difference;
    wire [7:0] borrow_generate, borrow_propagate;
    wire [8:0] borrow;  // One extra bit for the initial borrow-in (0)
    
    // Extract 8-bit operands from inputs
    assign minuend = data_i[7:0];       // First operand
    assign subtrahend = {3'b000, shift_i}; // Second operand (using shift_i as operand)
    
    // Borrow generate and propagate signals
    generate
        genvar i;
        for (i = 0; i < 8; i = i + 1) begin: borrow_logic
            // Generate: Bi = ~Ai & Bi
            assign borrow_generate[i] = ~minuend[i] & subtrahend[i];
            
            // Propagate: Pi = Ai ^ Bi
            assign borrow_propagate[i] = minuend[i] ^ subtrahend[i];
        end
    endgenerate
    
    // Initial borrow-in is 0
    assign borrow[0] = 1'b0;
    
    // Look-ahead borrow calculation
    assign borrow[1] = borrow_generate[0];
    assign borrow[2] = borrow_generate[1] | (borrow_propagate[1] & borrow[1]);
    assign borrow[3] = borrow_generate[2] | (borrow_propagate[2] & borrow[2]);
    assign borrow[4] = borrow_generate[3] | (borrow_propagate[3] & borrow[3]);
    assign borrow[5] = borrow_generate[4] | (borrow_propagate[4] & borrow[4]);
    assign borrow[6] = borrow_generate[5] | (borrow_propagate[5] & borrow[5]);
    assign borrow[7] = borrow_generate[6] | (borrow_propagate[6] & borrow[6]);
    assign borrow[8] = borrow_generate[7] | (borrow_propagate[7] & borrow[7]);
    
    // Compute difference
    generate
        for (i = 0; i < 8; i = i + 1) begin: diff_calc
            assign difference[i] = borrow_propagate[i] ^ borrow[i];
        end
    endgenerate
    
    // Register the output
    always @(posedge clk_i) begin
        if (en_i) begin
            data_o <= {{(DW-8){difference[7]}}, difference}; // Sign-extend the result
        end
    end
endmodule