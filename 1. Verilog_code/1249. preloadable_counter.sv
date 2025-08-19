module preloadable_counter (
    input wire clk, sync_rst, load, en,
    input wire [5:0] preset_val,
    output reg [5:0] q
);
    always @(posedge clk) begin
        if (sync_rst)
            q <= 6'b000000;
        else if (load)
            q <= preset_val;
        else if (en)
            q <= q + 1'b1;
    end
endmodule