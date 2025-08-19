//SystemVerilog
module data_encrypt #(parameter DW=16) (
    input wire clk,
    input wire en,
    input wire [DW-1:0] din,
    input wire [DW-1:0] key,
    output reg [DW-1:0] dout
);

    wire [DW-1:0] encrypt_comb_out;

    data_encrypt_comb #(.DW(DW)) u_data_encrypt_comb (
        .din(din),
        .key(key),
        .encrypt_out(encrypt_comb_out)
    );

    always @(posedge clk) begin
        if (en) begin
            dout <= encrypt_comb_out;
        end
    end

endmodule

module data_encrypt_comb #(parameter DW=16) (
    input wire [DW-1:0] din,
    input wire [DW-1:0] key,
    output wire [DW-1:0] encrypt_out
);

    wire [DW-1:0] swapped_din;
    wire [DW-1:0] xor_result;

    assign swapped_din = {din[7:0], din[15:8]};
    assign xor_result = swapped_din ^ key;
    assign encrypt_out = xor_result;

endmodule