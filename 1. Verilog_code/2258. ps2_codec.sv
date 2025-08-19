module ps2_codec (
    input clk_ps2, data,
    output reg [7:0] keycode,
    output reg parity_ok
);
    reg [10:0] shift;
    always @(negedge clk_ps2) begin
        shift <= {data, shift[10:1]};
        if(shift[0]) begin
            parity_ok <= (^shift[8:1] == shift[9]);
            keycode <= shift[8:1];
        end
    end
endmodule