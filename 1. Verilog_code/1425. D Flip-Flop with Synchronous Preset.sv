module d_ff_sync_preset (
    input wire clk,
    input wire preset,
    input wire d,
    output reg q
);
    always @(posedge clk) begin
        if (preset)
            q <= 1'b1;
        else
            q <= d;
    end
endmodule