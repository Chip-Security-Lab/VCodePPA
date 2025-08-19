//SystemVerilog
// Top-level module: rotate_left_pipeline
module rotate_left_pipeline(
    input clk,
    input rst,
    input valid_in,
    input [31:0] data,
    input [4:0] amount,
    output reg valid_out,
    output reg [31:0] result
);

    // Stage 1: Calculate shifted left and shifted right
    reg [31:0] data_stage1;
    reg [4:0] amount_stage1;
    reg valid_stage1;
    reg [31:0] shift_left_stage1;
    reg [31:0] shift_right_stage1;

    always @(posedge clk) begin
        if (rst) begin
            data_stage1         <= 32'd0;
            amount_stage1       <= 5'd0;
            shift_left_stage1   <= 32'd0;
            shift_right_stage1  <= 32'd0;
            valid_stage1        <= 1'b0;
        end else begin
            data_stage1         <= data;
            amount_stage1       <= amount;
            shift_left_stage1   <= data << amount;
            shift_right_stage1  <= data >> (32 - amount);
            valid_stage1        <= valid_in;
        end
    end

    // Stage 2: OR the two shifted results
    reg [31:0] shift_left_stage2;
    reg [31:0] shift_right_stage2;
    reg [4:0] amount_stage2;
    reg valid_stage2;

    always @(posedge clk) begin
        if (rst) begin
            shift_left_stage2   <= 32'd0;
            shift_right_stage2  <= 32'd0;
            amount_stage2       <= 5'd0;
            valid_stage2        <= 1'b0;
        end else begin
            shift_left_stage2   <= shift_left_stage1;
            shift_right_stage2  <= shift_right_stage1;
            amount_stage2       <= amount_stage1;
            valid_stage2        <= valid_stage1;
        end
    end

    // Stage 3: Output result
    always @(posedge clk) begin
        if (rst) begin
            result      <= 32'd0;
            valid_out   <= 1'b0;
        end else begin
            result      <= shift_left_stage2 | shift_right_stage2;
            valid_out   <= valid_stage2;
        end
    end

endmodule

// 5. Rotate Right with Enable, Pipelined Version
module ror_module_pipeline #(
    parameter WIDTH = 8
)(
    input clk,
    input rst,
    input en,
    input valid_in,
    input [WIDTH-1:0] data_in,
    input [$clog2(WIDTH)-1:0] rotate_by,
    output reg valid_out,
    output reg [WIDTH-1:0] data_out
);

    // Stage 1: Prepare concatenated data and shift amount
    reg [WIDTH-1:0] data_in_stage1;
    reg [$clog2(WIDTH)-1:0] rotate_by_stage1;
    reg en_stage1;
    reg valid_stage1;

    always @(posedge clk) begin
        if (rst) begin
            data_in_stage1      <= {WIDTH{1'b0}};
            rotate_by_stage1    <= {($clog2(WIDTH)){1'b0}};
            en_stage1           <= 1'b0;
            valid_stage1        <= 1'b0;
        end else begin
            data_in_stage1      <= data_in;
            rotate_by_stage1    <= rotate_by;
            en_stage1           <= en;
            valid_stage1        <= valid_in;
        end
    end

    // Stage 2: Perform rotation and output
    reg [2*WIDTH-1:0] concat_data_stage2;
    reg [$clog2(WIDTH)-1:0] rotate_by_stage2;
    reg en_stage2;
    reg valid_stage2;

    always @(posedge clk) begin
        if (rst) begin
            concat_data_stage2  <= {(2*WIDTH){1'b0}};
            rotate_by_stage2    <= {($clog2(WIDTH)){1'b0}};
            en_stage2           <= 1'b0;
            valid_stage2        <= 1'b0;
        end else begin
            concat_data_stage2  <= {data_in_stage1, data_in_stage1};
            rotate_by_stage2    <= rotate_by_stage1;
            en_stage2           <= en_stage1;
            valid_stage2        <= valid_stage1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            data_out    <= {WIDTH{1'b0}};
            valid_out   <= 1'b0;
        end else if (en_stage2 && valid_stage2) begin
            data_out    <= concat_data_stage2 >> rotate_by_stage2;
            valid_out   <= 1'b1;
        end else begin
            data_out    <= data_out;
            valid_out   <= 1'b0;
        end
    end

endmodule