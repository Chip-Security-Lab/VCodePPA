//SystemVerilog
module serial2parallel_converter #(
    parameter WORD_SIZE = 8
) (
    input  wire clk,
    input  wire n_reset,
    input  wire serial_in,
    input  wire load_en,
    output reg  [WORD_SIZE-1:0] parallel_out,
    output reg  conversion_done
);
    reg [WORD_SIZE-1:0] shift_reg;
    reg [$clog2(WORD_SIZE)-1:0] bit_counter;
    reg [$clog2(WORD_SIZE)-1:0] next_counter;
    reg counter_max;
    
    // 预计算逻辑移到组合逻辑部分
    always @(*) begin
        next_counter = bit_counter + 1'b1;
        counter_max = (bit_counter == WORD_SIZE-1);
    end
    
    always @(posedge clk or negedge n_reset) begin
        if (!n_reset) begin
            conversion_done <= 1'b0;
            shift_reg <= {WORD_SIZE{1'b0}};
            bit_counter <= {$clog2(WORD_SIZE){1'b0}};
            parallel_out <= {WORD_SIZE{1'b0}};
        end else if (load_en) begin
            shift_reg <= {shift_reg[WORD_SIZE-2:0], serial_in};
            conversion_done <= counter_max;
            bit_counter <= counter_max ? {$clog2(WORD_SIZE){1'b0}} : next_counter;
            parallel_out <= shift_reg;
        end
    end
endmodule