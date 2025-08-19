//SystemVerilog
module manchester_encoder (
    input clk, rst_n,
    input data_in,
    output reg encoded_out
);
    wire data_comb;
    assign data_comb = data_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_out <= 1'b0;
        end else begin
            if (data_comb)
                encoded_out <= ~encoded_out;
        end
    end
endmodule