module compare_match_timer (
    input i_clock, i_nreset, i_enable,
    input [23:0] i_compare,
    output reg o_match,
    output [23:0] o_counter
);
    reg [23:0] timer_cnt;
    always @(posedge i_clock) begin
        if (!i_nreset) timer_cnt <= 24'h000000;
        else if (i_enable) timer_cnt <= timer_cnt + 24'h000001;
    end
    always @(posedge i_clock) begin
        if (!i_nreset) o_match <= 1'b0;
        else o_match <= (timer_cnt == i_compare) && i_enable;
    end
    assign o_counter = timer_cnt;
endmodule