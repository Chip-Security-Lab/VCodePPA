//SystemVerilog
module SignExtendShifter #(parameter WIDTH=8) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  arith_shift,
    input  wire signed [WIDTH-1:0] data_in,
    input  wire                  valid_in,
    output reg  signed [WIDTH-1:0] data_out,
    output reg                   valid_out
);

    // Stage 1: Input Registering
    reg signed [WIDTH-1:0] data_in_stage1;
    reg                    arith_shift_stage1;
    reg                    valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1      <= {WIDTH{1'b0}};
            arith_shift_stage1  <= 1'b0;
            valid_stage1        <= 1'b0;
        end else begin
            data_in_stage1      <= data_in;
            arith_shift_stage1  <= arith_shift;
            valid_stage1        <= valid_in;
        end
    end

    // Stage 2: Compute Shift Results
    reg signed [WIDTH-1:0] shift_left_result_stage2;
    reg signed [WIDTH-1:0] shift_right_result_stage2;
    reg                    arith_shift_stage2;
    reg                    valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_left_result_stage2     <= {WIDTH{1'b0}};
            shift_right_result_stage2    <= {WIDTH{1'b0}};
            arith_shift_stage2           <= 1'b0;
            valid_stage2                 <= 1'b0;
        end else begin
            // Shift left operation (arithmetic left shift is same as logical for 2's complement)
            shift_left_result_stage2  <= data_in_stage1 <<< 1;

            // Arithmetic right shift using 2's complement subtraction
            // data_in >>> 1 == (data_in - (data_in[0] ? 1 : 0)) >> 1 for signed numbers
            // Implement as (data_in - 1) >>> 1
            shift_right_result_stage2 <= (data_in_stage1 - {{(WIDTH-1){1'b0}}, 1'b1}) >>> 1;

            arith_shift_stage2        <= arith_shift_stage1;
            valid_stage2              <= valid_stage1;
        end
    end

    // Stage 3: Output Selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            if (arith_shift_stage2)
                data_out <= shift_right_result_stage2;
            else
                data_out <= shift_left_result_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule