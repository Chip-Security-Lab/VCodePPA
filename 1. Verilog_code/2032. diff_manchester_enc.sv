module diff_manchester_enc (
    input clk, rst_n,
    input data_in,
    output reg encoded
);
    reg prev_bit;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) {encoded, prev_bit} <= 0;
        else begin
            encoded <= prev_bit ^ data_in;
            prev_bit <= encoded;
        end
    end
endmodule
