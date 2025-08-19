module config_encoding_ring #(
    parameter ENCODING = "ONEHOT" // or "BINARY"
)(
    input clk, rst,
    output reg [3:0] code_out
);
always @(posedge clk) begin
    if (rst) code_out <= (ENCODING == "ONEHOT") ? 4'b0001 : 4'b0000;
    else case(ENCODING)
        "ONEHOT": code_out <= {code_out[0], code_out[3:1]};
        "BINARY": code_out <= (code_out == 4'b1000) ? 4'b0001 : code_out << 1;
    endcase
end
endmodule
