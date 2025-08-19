//SystemVerilog
module ror_module_pipeline #(
    parameter WIDTH = 8
)(
    input clk,
    input rst,
    input en,
    input [WIDTH-1:0] data_in,
    input [$clog2(WIDTH)-1:0] rotate_by,
    output reg [WIDTH-1:0] data_out,
    output reg valid_out
);

    // Stage 1: Capture inputs
    reg [WIDTH-1:0] data_in_stage1;
    reg [$clog2(WIDTH)-1:0] rotate_by_stage1;
    reg valid_stage1;

    // Stage 2: Concatenate and shift
    reg [2*WIDTH-1:0] concat_data_stage2;
    reg [$clog2(WIDTH)-1:0] rotate_by_stage2;
    reg valid_stage2;

    // Stage 3: Extract rotated data
    reg [WIDTH-1:0] rotated_data_stage3;
    reg valid_stage3;

    // Pipeline Stage 1
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_in_stage1 <= {WIDTH{1'b0}};
            rotate_by_stage1 <= {($clog2(WIDTH)){1'b0}};
            valid_stage1 <= 1'b0;
        end else if (en) begin
            data_in_stage1 <= data_in;
            rotate_by_stage1 <= rotate_by;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Pipeline Stage 2
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            concat_data_stage2 <= {(2*WIDTH){1'b0}};
            rotate_by_stage2 <= {($clog2(WIDTH)){1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            concat_data_stage2 <= {data_in_stage1, data_in_stage1};
            rotate_by_stage2 <= rotate_by_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Pipeline Stage 3
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rotated_data_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            rotated_data_stage3 <= concat_data_stage2 >> rotate_by_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Output register and valid signal
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            data_out <= rotated_data_stage3;
            valid_out <= valid_stage3;
        end
    end

endmodule