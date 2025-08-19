module prescaled_timer (
    input wire i_clk, i_arst, i_enable,
    input wire [7:0] i_prescale,
    input wire [15:0] i_max,
    output reg [15:0] o_count,
    output wire o_match
);
    reg [7:0] pre_cnt;
    wire pre_tick;
    always @(posedge i_clk or posedge i_arst) begin
        if (i_arst) pre_cnt <= 8'd0;
        else if (i_enable) pre_cnt <= (pre_cnt >= i_prescale) ? 8'd0 : pre_cnt + 8'd1;
    end
    assign pre_tick = (pre_cnt == i_prescale);
    always @(posedge i_clk or posedge i_arst) begin
        if (i_arst) o_count <= 16'd0;
        else if (i_enable && pre_tick) o_count <= (o_count >= i_max) ? 16'd0 : o_count + 16'd1;
    end
    assign o_match = (o_count == i_max);
endmodule