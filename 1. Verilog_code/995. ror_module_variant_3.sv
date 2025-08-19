//SystemVerilog
module ror_module #(
    parameter WIDTH = 8
)(
    input                        clk,
    input                        rst,
    input                        en,
    input      [WIDTH-1:0]       data_in,
    input      [$clog2(WIDTH)-1:0] rotate_by,
    output reg [WIDTH-1:0]       data_out,
    output reg                   valid_out
);

    // Stage 1: Rotate calculation (moved registers after combinational logic)
    wire [2*WIDTH-1:0]           data_concat_comb;
    wire [$clog2(WIDTH)-1:0]     rotate_by_comb;
    wire                         valid_comb;

    assign data_concat_comb = {data_in, data_in};
    assign rotate_by_comb   = rotate_by;
    assign valid_comb       = en;

    // Stage 2: Register after rotate calculation
    reg [2*WIDTH-1:0]            data_concat_stage2;
    reg [$clog2(WIDTH)-1:0]      rotate_by_stage2;
    reg                          valid_stage2;

    always @(posedge clk) begin
        if (rst) begin
            data_concat_stage2 <= {(2*WIDTH){1'b0}};
            rotate_by_stage2   <= {($clog2(WIDTH)){1'b0}};
            valid_stage2       <= 1'b0;
        end else begin
            data_concat_stage2 <= data_concat_comb;
            rotate_by_stage2   <= rotate_by_comb;
            valid_stage2       <= valid_comb;
        end
    end

    // Stage 3: Output Register
    reg [WIDTH-1:0]              data_out_stage3;
    reg                          valid_stage3;

    always @(posedge clk) begin
        if (rst) begin
            data_out_stage3 <= {WIDTH{1'b0}};
            valid_stage3    <= 1'b0;
        end else begin
            data_out_stage3 <= data_concat_stage2 >> rotate_by_stage2;
            valid_stage3    <= valid_stage2;
        end
    end

    // Output assignment
    always @(posedge clk) begin
        if (rst) begin
            data_out  <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            data_out  <= data_out_stage3;
            valid_out <= valid_stage3;
        end
    end

endmodule