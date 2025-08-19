//SystemVerilog
module rng_cnt_xor_11(
    input            clk,
    input            rst,
    input            en,
    output reg [7:0] rnd
);

    reg [7:0] cnt;

    // Counter logic: Handles counter increment and reset
    always @(posedge clk) begin
        if (rst)
            cnt <= 8'b0;
        else if (en)
            cnt <= cnt + 1'b1;
    end

    // Output logic: Updates rnd based on the current counter value
    always @(posedge clk) begin
        rnd <= cnt ^ {cnt[3:0], cnt[7:4]};
    end

endmodule