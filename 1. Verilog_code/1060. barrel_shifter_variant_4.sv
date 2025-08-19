//SystemVerilog
// Optimized Top-level pipelined barrel shifter module with forward register retiming
module barrel_shifter #(parameter WIDTH = 8) (
    input                  clk,
    input                  rst_n,
    input  [WIDTH-1:0]     data_in,
    input  [2:0]           shift_in,
    output [WIDTH-1:0]     result_out
);

    // Stage 1: Combinational logic for left and right shifts (moved registers after logic)
    wire [WIDTH-1:0]       left_shift_comb;
    wire [WIDTH-1:0]       right_shift_comb;
    wire [2:0]             shift_comb;

    assign left_shift_comb  = data_in << shift_in;
    assign right_shift_comb = data_in >> (WIDTH - shift_in);
    assign shift_comb       = shift_in;

    // Stage 2: Register the outputs of combinational logic (moved registers forward)
    reg [WIDTH-1:0]        left_shift_stage2;
    reg [WIDTH-1:0]        right_shift_stage2;
    reg [2:0]              shift_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_shift_stage2  <= {WIDTH{1'b0}};
            right_shift_stage2 <= {WIDTH{1'b0}};
            shift_stage2       <= 3'd0;
        end else begin
            left_shift_stage2  <= left_shift_comb;
            right_shift_stage2 <= right_shift_comb;
            shift_stage2       <= shift_comb;
        end
    end

    // Stage 3: Register the OR merge result (as before)
    reg [WIDTH-1:0]        result_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage3 <= {WIDTH{1'b0}};
        end else begin
            result_stage3 <= left_shift_stage2 | right_shift_stage2;
        end
    end

    assign result_out = result_stage3;

endmodule