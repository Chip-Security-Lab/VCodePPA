//SystemVerilog
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
    reg [WORD_SIZE-1:0] lut_next_counter;
    reg conversion_done_reg;
    
    // Lookup table for next counter state
    always @(*) begin
        case (bit_counter)
            3'b000: lut_next_counter = 3'b001;
            3'b001: lut_next_counter = 3'b010;
            3'b010: lut_next_counter = 3'b011;
            3'b011: lut_next_counter = 3'b100;
            3'b100: lut_next_counter = 3'b101;
            3'b101: lut_next_counter = 3'b110;
            3'b110: lut_next_counter = 3'b111;
            3'b111: lut_next_counter = 3'b000;
            default: lut_next_counter = 3'b000;
        endcase
    end
    
    assign parallel_out = shift_reg;
    assign conversion_done = conversion_done_reg;
    
    always @(posedge clk or negedge n_reset) begin
        if (!n_reset) begin
            shift_reg <= {WORD_SIZE{1'b0}};
            bit_counter <= {$clog2(WORD_SIZE){1'b0}};
            conversion_done_reg <= 1'b0;
        end else if (load_en) begin
            shift_reg <= {shift_reg[WORD_SIZE-2:0], serial_in};
            conversion_done_reg <= (bit_counter == WORD_SIZE-1);
            bit_counter <= lut_next_counter[($clog2(WORD_SIZE)-1):0];
        end
    end
endmodule