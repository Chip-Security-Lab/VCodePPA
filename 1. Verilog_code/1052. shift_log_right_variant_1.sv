//SystemVerilog
module shift_log_right #(parameter WIDTH=8, SHIFT=2) (
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out,
    input  wire clk,
    input  wire rst_n
);

    // Stage 1: Input register for data_in
    reg [WIDTH-1:0] reg_data_stage1;
    // Stage 2: Shift logic output register
    reg [WIDTH-1:0] reg_data_stage2;

    // Internal signals for conditional inversion subtractor
    wire [WIDTH-1:0] shift_mask;
    wire [WIDTH-1:0] shifted_input;
    wire [WIDTH-1:0] inverted_shift_mask;
    wire [WIDTH-1:0] subtrahend;
    wire [WIDTH-1:0] sum_result;
    wire             carry_in;
    wire             carry_out;

    // Stage 1: Capture input data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_data_stage1 <= {WIDTH{1'b0}};
        end else begin
            reg_data_stage1 <= data_in;
        end
    end

    // Generate shift_mask (1 << SHIFT) - 1
    assign shift_mask = ({{(WIDTH){1'b0}}} | ((1 << SHIFT) - 1));

    // Shifted input for logical right shift
    assign shifted_input = { {SHIFT{1'b0}}, reg_data_stage1[WIDTH-1:SHIFT] };

    // Conditional inversion subtractor logic for reg_data_stage1 >> SHIFT
    // Equivalent to (reg_data_stage1 - shift_mask) >> SHIFT
    // Using conditional inversion subtractor: A - B = A + (~B) + 1
    assign inverted_shift_mask = ~shift_mask;
    assign subtrahend = inverted_shift_mask;
    assign carry_in = 1'b1;

    assign {carry_out, sum_result} = {1'b0, reg_data_stage1} + {1'b0, subtrahend} + carry_in;

    // Final shifted result
    wire [WIDTH-1:0] shifted_result;
    assign shifted_result = sum_result >> SHIFT;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_data_stage2 <= {WIDTH{1'b0}};
        end else begin
            reg_data_stage2 <= shifted_result;
        end
    end

    assign data_out = reg_data_stage2;

endmodule