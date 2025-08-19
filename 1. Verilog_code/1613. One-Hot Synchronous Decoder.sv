module onehot_sync_decoder (
    input wire clock,
    input wire enable,
    input wire [2:0] addr_in,
    output reg [7:0] decode_out
);
    always @(posedge clock) begin
        if (enable)
            decode_out <= (8'b1 << addr_in);
        else
            decode_out <= 8'b0;
    end
endmodule