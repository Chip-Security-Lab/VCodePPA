//SystemVerilog
module TriNor(
    input        clk,
    input        rst_n,
    input        en,
    input  [7:0] a,
    input  [7:0] b,
    output reg [15:0] y
);
    reg [15:0] product;
    reg [7:0]  multiplicand;
    reg [7:0]  multiplier;
    reg [3:0]  bit_count;
    reg        busy;
    reg        start;

    // Control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product      <= 16'b0;
            multiplicand <= 8'b0;
            multiplier   <= 8'b0;
            bit_count    <= 4'b0;
            busy         <= 1'b0;
            start        <= 1'b0;
            y            <= 16'bz;
        end else begin
            if (en && !busy) begin
                multiplicand <= a;
                multiplier   <= b;
                product      <= 16'b0;
                bit_count    <= 4'd0;
                busy         <= 1'b1;
                start        <= 1'b1;
                y            <= 16'bz;
            end else if (busy) begin
                if (multiplier[0]) begin
                    product <= product + (multiplicand << bit_count);
                end
                multiplier <= multiplier >> 1;
                bit_count  <= bit_count + 1'b1;
                start      <= 1'b0;
                if (bit_count == 4'd7) begin
                    busy <= 1'b0;
                    y    <= ~(product + ((multiplier[0]) ? (multiplicand << bit_count) : 16'b0));
                end
            end else begin
                if (!en)
                    y <= 16'bz;
            end
        end
    end
endmodule