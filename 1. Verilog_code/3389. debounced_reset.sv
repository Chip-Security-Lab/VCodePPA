module debounced_reset #(
    parameter DEBOUNCE_COUNT = 3
)(
    input wire clk,
    input wire noisy_reset,
    output reg clean_reset
);
    reg [1:0] count;
    reg reset_ff;
    always @(posedge clk) begin
        reset_ff <= noisy_reset;
        if (reset_ff != noisy_reset) 
            count <= 0;
        else if (count < DEBOUNCE_COUNT)
            count <= count + 1'b1;
        else
            clean_reset <= reset_ff;
    end
endmodule