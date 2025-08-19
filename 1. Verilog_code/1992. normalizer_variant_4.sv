//SystemVerilog
module normalizer #(
    parameter WIDTH = 16
)(
    input wire [WIDTH-1:0] in_data,
    output reg [WIDTH-1:0] normalized_data,
    output reg [$clog2(WIDTH)-1:0] shift_count
);

    integer i;
    reg found;

    // Intermediate wires for multi-level shifting
    wire [WIDTH-1:0] stage_shift [0:$clog2(WIDTH)];
    reg [$clog2(WIDTH)-1:0] local_shift_count;

    // Subtractor signals for conditional inversion subtractor
    wire [7:0] sub_a, sub_b;
    wire [7:0] sub_result;
    wire sub_borrow;

    // Find shift_count (leading zero count)
    always @* begin
        found = 1'b0;
        local_shift_count = {$clog2(WIDTH){1'b0}};
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (!found && in_data[i]) begin
                found = 1'b1;
                local_shift_count = WIDTH-1-i;
            end
        end
        shift_count = local_shift_count;
    end

    // Barrel shifter implementation
    assign stage_shift[0] = in_data;
    genvar j;
    generate
        for (j = 0; j < $clog2(WIDTH); j = j + 1) begin : gen_barrel
            wire [WIDTH-1:0] prev_stage = stage_shift[j];
            wire [WIDTH-1:0] next_stage;
            assign next_stage = (shift_count[j]) ?
                {prev_stage[WIDTH-1-(1<<j):0], {(1<<j){1'b0}}} :
                prev_stage;
            assign stage_shift[j+1] = next_stage;
        end
    endgenerate

    always @* begin
        normalized_data = stage_shift[$clog2(WIDTH)];
    end

endmodule

// 8-bit conditional inversion subtractor module
module cond_inv_subtractor_8bit (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    output wire [7:0] difference,
    output wire       borrow
);
    wire [7:0] subtrahend_inv;
    wire [7:0] add_result;
    wire       carry_out;

    // Conditional inversion for subtraction: A - B = A + (~B) + 1
    assign subtrahend_inv = ~subtrahend;
    assign {carry_out, add_result} = minuend + subtrahend_inv + 1'b1;

    assign difference = add_result;
    assign borrow = ~carry_out;
endmodule