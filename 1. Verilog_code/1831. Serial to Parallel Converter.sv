module serial2parallel_converter #(
    parameter WORD_SIZE = 8
) (
    input  wire clk,
    input  wire n_reset,
    input  wire serial_in,
    input  wire load_en,
    output wire [WORD_SIZE-1:0] parallel_out,
    output wire conversion_done
);
    reg [WORD_SIZE-1:0] shift_reg;
    reg [$clog2(WORD_SIZE)-1:0] bit_counter;
    
    assign parallel_out = shift_reg;
    assign conversion_done = (bit_counter == WORD_SIZE-1);
    
    always @(posedge clk or negedge n_reset) begin
        if (!n_reset) begin
            shift_reg <= {WORD_SIZE{1'b0}};
            bit_counter <= {$clog2(WORD_SIZE){1'b0}};
        end else if (load_en) begin
            shift_reg <= {shift_reg[WORD_SIZE-2:0], serial_in};
            bit_counter <= (bit_counter == WORD_SIZE-1) ? 
                          {$clog2(WORD_SIZE){1'b0}} : bit_counter + 1'b1;
        end
    end
endmodule