//SystemVerilog

module gray2bin_seq #(
    parameter DATA_W = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  enable,
    input  wire [DATA_W-1:0]     gray_code,
    output reg  [DATA_W-1:0]     binary_out
);

    wire [DATA_W-1:0]            binary_comb;

    gray2bin_comb #(
        .DATA_W(DATA_W)
    ) u_gray2bin_comb (
        .gray_code(gray_code),
        .binary_out(binary_comb)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            binary_out <= {DATA_W{1'b0}};
        else if (enable)
            binary_out <= binary_comb;
    end

endmodule

module gray2bin_comb #(
    parameter DATA_W = 8
)(
    input  wire [DATA_W-1:0] gray_code,
    output wire [DATA_W-1:0] binary_out
);

    reg [DATA_W-1:0] binary_temp;
    integer j;

    always @(*) begin
        binary_temp[DATA_W-1] = gray_code[DATA_W-1];
        for (j = DATA_W-2; j >= 0; j = j - 1) begin
            binary_temp[j] = gray_code[j] ^ binary_temp[j+1];
        end
    end

    assign binary_out = binary_temp;

endmodule