//SystemVerilog
module error_detect_decoder_with_multiplier(
    input [1:0] addr,
    input valid,
    input clk,
    input reset,
    input start_multiply,
    input [3:0] multiplier,
    input [3:0] multiplicand,
    output [3:0] select,
    output error,
    output [7:0] product,
    output multiply_done
);

    // Instantiate the decoder submodule
    error_detect_decoder decoder_unit (
        .addr(addr),
        .valid(valid),
        .select(select),
        .error(error)
    );

    // Instantiate the multiplier submodule
    shift_add_multiplier multiplier_unit (
        .clk(clk),
        .reset(reset),
        .start_multiply(start_multiply),
        .multiplier(multiplier),
        .multiplicand(multiplicand),
        .product(product),
        .multiply_done(multiply_done)
    );

endmodule

// Decoder submodule handles address decoding and error detection
module error_detect_decoder(
    input [1:0] addr,
    input valid,
    output reg [3:0] select,
    output reg error
);
    
    always @(*) begin
        select = 4'b0000;
        error = 1'b0;
        
        if (valid)
            select[addr] = 1'b1;
        else
            error = 1'b1;
    end
    
endmodule

// Multiplier submodule implements the shift-and-add multiplication algorithm
module shift_add_multiplier #(
    parameter WIDTH = 4
)(
    input clk,
    input reset,
    input start_multiply,
    input [WIDTH-1:0] multiplier,
    input [WIDTH-1:0] multiplicand,
    output [WIDTH*2-1:0] product,
    output reg multiply_done
);

    // Internal registers for multiplication process
    reg [WIDTH-1:0] mcand_reg;
    reg [WIDTH-1:0] mplier_reg;
    reg [WIDTH*2-1:0] product_reg;
    reg [$clog2(WIDTH+1)-1:0] bit_counter;
    reg computing;
    
    // Connect the product register to the output
    assign product = product_reg;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mcand_reg <= {WIDTH{1'b0}};
            mplier_reg <= {WIDTH{1'b0}};
            product_reg <= {WIDTH*2{1'b0}};
            bit_counter <= {$clog2(WIDTH+1){1'b0}};
            computing <= 1'b0;
            multiply_done <= 1'b0;
        end
        else begin
            if (start_multiply && !computing) begin
                // Initialize for a new multiplication
                mcand_reg <= multiplicand;
                mplier_reg <= multiplier;
                product_reg <= {WIDTH*2{1'b0}};
                bit_counter <= WIDTH; // WIDTH-bit multiplication requires WIDTH iterations
                computing <= 1'b1;
                multiply_done <= 1'b0;
            end
            else if (computing) begin
                if (bit_counter > 0) begin
                    // Check the LSB of multiplier
                    if (mplier_reg[0]) begin
                        // Add multiplicand to the product if the bit is 1
                        product_reg[WIDTH*2-1:WIDTH] <= product_reg[WIDTH*2-1:WIDTH] + mcand_reg;
                    end
                    
                    // Shift the product right and the multiplier right
                    product_reg <= {1'b0, product_reg[WIDTH*2-1:1]};
                    mplier_reg <= {1'b0, mplier_reg[WIDTH-1:1]};
                    
                    // Decrement the counter
                    bit_counter <= bit_counter - 1'b1;
                end
                else begin
                    // Multiplication complete
                    computing <= 1'b0;
                    multiply_done <= 1'b1;
                end
            end
        end
    end

endmodule