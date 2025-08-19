//SystemVerilog
module cascadable_divider (
    input clk_in,
    input cascade_en,
    output reg clk_out,
    output cascade_out
);
reg [7:0] counter;
wire [7:0] next_counter;
wire [7:0] increment;
wire [7:0] carry_chain;

assign increment = 8'b00000001;

// 优化进位链计算
assign carry_chain[0] = counter[0];
assign carry_chain[1] = counter[1] | (counter[0] & counter[1]);
assign carry_chain[2] = counter[2] | (counter[1] & counter[2]) | (counter[0] & counter[1] & counter[2]);
assign carry_chain[3] = counter[3] | (counter[2] & counter[3]) | (counter[1] & counter[2] & counter[3]) | (counter[0] & counter[1] & counter[2] & counter[3]);
assign carry_chain[4] = counter[4] | (counter[3] & counter[4]) | (counter[2] & counter[3] & counter[4]) | (counter[1] & counter[2] & counter[3] & counter[4]) | (counter[0] & counter[1] & counter[2] & counter[3] & counter[4]);
assign carry_chain[5] = counter[5] | (counter[4] & counter[5]) | (counter[3] & counter[4] & counter[5]) | (counter[2] & counter[3] & counter[4] & counter[5]) | (counter[1] & counter[2] & counter[3] & counter[4] & counter[5]) | (counter[0] & counter[1] & counter[2] & counter[3] & counter[4] & counter[5]);
assign carry_chain[6] = counter[6] | (counter[5] & counter[6]) | (counter[4] & counter[5] & counter[6]) | (counter[3] & counter[4] & counter[5] & counter[6]) | (counter[2] & counter[3] & counter[4] & counter[5] & counter[6]) | (counter[1] & counter[2] & counter[3] & counter[4] & counter[5] & counter[6]) | (counter[0] & counter[1] & counter[2] & counter[3] & counter[4] & counter[5] & counter[6]);
assign carry_chain[7] = counter[7] | (counter[6] & counter[7]) | (counter[5] & counter[6] & counter[7]) | (counter[4] & counter[5] & counter[6] & counter[7]) | (counter[3] & counter[4] & counter[5] & counter[6] & counter[7]) | (counter[2] & counter[3] & counter[4] & counter[5] & counter[6] & counter[7]) | (counter[1] & counter[2] & counter[3] & counter[4] & counter[5] & counter[6] & counter[7]) | (counter[0] & counter[1] & counter[2] & counter[3] & counter[4] & counter[5] & counter[6] & counter[7]);

// 优化加法器计算
assign next_counter[0] = ~counter[0];
assign next_counter[1] = counter[1] ^ carry_chain[0];
assign next_counter[2] = counter[2] ^ carry_chain[1];
assign next_counter[3] = counter[3] ^ carry_chain[2];
assign next_counter[4] = counter[4] ^ carry_chain[3];
assign next_counter[5] = counter[5] ^ carry_chain[4];
assign next_counter[6] = counter[6] ^ carry_chain[5];
assign next_counter[7] = counter[7] ^ carry_chain[6];

always @(posedge clk_in) begin
    if (counter == 8'd9) begin
        counter <= 0;
        clk_out <= ~clk_out;
    end else begin
        counter <= next_counter;
    end
end

assign cascade_out = (counter == 8'd9) ? 1'b1 : 1'b0;
endmodule