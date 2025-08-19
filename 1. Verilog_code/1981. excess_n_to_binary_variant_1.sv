//SystemVerilog
module excess_n_to_binary #(parameter WIDTH=8, N=127)(
    input wire [WIDTH-1:0] excess_n_in,
    output reg [WIDTH-1:0] binary_out
);

    wire [WIDTH-1:0] lut_sub_result;

    subtractor_lut8 sub_lut_inst (
        .input_a(excess_n_in),
        .input_b(N[WIDTH-1:0]),
        .diff(lut_sub_result)
    );

    always @* begin
        binary_out = lut_sub_result;
    end

endmodule

module subtractor_lut8(
    input  wire [7:0] input_a,
    input  wire [7:0] input_b,
    output wire [7:0] diff
);
    reg [7:0] lut_diff [0:65535];
    reg [7:0] diff_reg;
    wire [15:0] lut_addr;

    assign lut_addr = {input_a, input_b};
    assign diff = diff_reg;

    integer i, j;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                lut_diff[{i[7:0], j[7:0]}] = i - j;
            end
        end
    end

    always @* begin
        diff_reg = lut_diff[lut_addr];
    end

endmodule