module d_latch_active_low (
    input wire data_in,
    input wire en_n,     // Active low enable
    output reg data_out
);
    always @* begin
        if (!en_n)
            data_out = data_in;
    end
endmodule