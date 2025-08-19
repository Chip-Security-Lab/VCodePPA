//SystemVerilog
module bin_to_onehot #(
    parameter BIN_WIDTH = 4
)(
    input wire [BIN_WIDTH-1:0] bin_in,
    input wire enable,
    output reg [(1<<BIN_WIDTH)-1:0] onehot_out
);
    wire [BIN_WIDTH-1:0] subtractor_a;
    wire [BIN_WIDTH-1:0] subtractor_b;
    wire [BIN_WIDTH-1:0] subtractor_result;

    assign subtractor_a = bin_in;
    assign subtractor_b = {BIN_WIDTH{1'b0}};

    lut_subtractor_4bit u_lut_subtractor_4bit (
        .a(subtractor_a),
        .b(subtractor_b),
        .diff(subtractor_result)
    );

    integer i;
    always @(*) begin
        onehot_out = {((1<<BIN_WIDTH)){1'b0}};
        if (enable && bin_in < (1<<BIN_WIDTH)) begin
            for (i = 0; i < (1<<BIN_WIDTH); i = i + 1) begin
                if (subtractor_result == i)
                    onehot_out[i] = 1'b1;
            end
        end
    end
endmodule

module lut_subtractor_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [3:0] diff
);
    reg [3:0] lut_diff [0:15][0:15];
    integer i, j;
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                lut_diff[i][j] = i - j;
            end
        end
    end

    always @(*) begin
        diff = lut_diff[a][b];
    end
endmodule