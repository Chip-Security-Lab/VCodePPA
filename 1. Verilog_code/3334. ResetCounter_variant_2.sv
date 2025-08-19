//SystemVerilog
// Top-level module: ResetCounter
module ResetCounter #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    output wire [WIDTH-1:0] reset_count
);
    // Internal signal for the counter value
    wire [WIDTH-1:0] reset_count_int;

    // Counter logic submodule instantiation
    ResetCounter_Counter #(
        .WIDTH(WIDTH)
    ) counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .count_out(reset_count_int)
    );

    assign reset_count = reset_count_int;

endmodule

// -----------------------------------------------------------------------------
// Submodule: ResetCounter_Counter
// Function: Implements the counter logic that increments on each negative edge
//           of rst_n, using clk for synchronization.
//           Subtraction operation is replaced by conditional add/sub algorithm.
// -----------------------------------------------------------------------------
module ResetCounter_Counter #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    output reg [WIDTH-1:0] count_out
);
    reg rst_n_d1;
    wire rst_n_falling_edge;
    wire [WIDTH-1:0] one_complement;
    wire [WIDTH-1:0] sum_result;
    wire carry_in;
    wire [WIDTH-1:0] adder_b;
    wire [WIDTH:0] adder_sum;

    // Register previous rst_n for edge detection
    always @(posedge clk) begin
        rst_n_d1 <= rst_n;
    end

    assign rst_n_falling_edge = (rst_n_d1 == 1'b1) && (rst_n == 1'b0);

    // Conditional adder/subtractor (conditional sum for increment)
    assign one_complement = { {(WIDTH-1){1'b0}}, 1'b1 }; // 8'b00000001
    assign adder_b = one_complement;
    assign carry_in = 1'b0;

    assign adder_sum = {1'b0, count_out} + {1'b0, adder_b} + carry_in;
    assign sum_result = adder_sum[WIDTH-1:0];

    always @(posedge clk) begin
        if (rst_n_falling_edge) begin
            count_out <= sum_result;
        end
    end
endmodule