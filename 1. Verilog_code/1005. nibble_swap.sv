module nibble_swap(
    input [15:0] data_in,
    input swap_en,
    output reg [15:0] data_out
);
    always @(*) begin
        if (swap_en)  // Swap nibbles: [D3|D2|D1|D0] -> [D0|D1|D2|D3]
            data_out = {data_in[3:0], data_in[7:4], data_in[11:8], data_in[15:12]};
        else
            data_out = data_in;
    end
endmodule