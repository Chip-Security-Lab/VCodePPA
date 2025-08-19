//SystemVerilog
module async_bridge #(parameter WIDTH=8) (
    input [WIDTH-1:0] a_data,
    input a_valid, b_ready,
    output [WIDTH-1:0] b_data,
    output a_ready, b_valid
);

    wire [WIDTH-1:0] b_data_internal;
    wire [WIDTH:0] borrow; // Borrow signals for each bit
    wire [WIDTH-1:0] a_data_complement; // Two's complement of a_data

    // Generate two's complement of a_data for subtraction
    assign a_data_complement = ~a_data + 1;

    // Initial borrow
    assign borrow[0] = 1'b0; 

    // Implementing the borrow logic for the borrow look-ahead subtractor
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : borrow_logic
            wire current_a_data_complement = a_data_complement[i];
            wire current_borrow = borrow[i];
            wire next_borrow;

            // Calculate b_data_internal and next borrow
            assign b_data_internal[i] = current_a_data_complement ^ current_borrow;
            assign next_borrow = (~current_a_data_complement & current_borrow) | (current_borrow & current_a_data_complement);
            assign borrow[i+1] = next_borrow;
        end
    endgenerate

    assign b_data = b_data_internal;
    assign b_valid = a_valid;
    assign a_ready = b_ready;

endmodule