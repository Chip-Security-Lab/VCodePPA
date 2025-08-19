module jk_ff_preset (
    input wire clk,
    input wire preset_n,
    input wire j,
    input wire k,
    output reg q
);
    always @(posedge clk or negedge preset_n) begin
        if (!preset_n)
            q <= 1'b1;  // Preset
        else begin
            case ({j, k})
                2'b00: q <= q;
                2'b01: q <= 1'b0;
                2'b10: q <= 1'b1;
                2'b11: q <= ~q;
            endcase
        end
    end
endmodule