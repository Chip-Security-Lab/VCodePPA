module async_combo_timer #(parameter CNT_WIDTH = 16)(
    input wire clock, reset, timer_en,
    input wire [CNT_WIDTH-1:0] max_count,
    output wire [CNT_WIDTH-1:0] counter_val,
    output wire timer_done
);
    reg [CNT_WIDTH-1:0] cnt_reg;
    always @(posedge clock) begin
        if (reset) cnt_reg <= {CNT_WIDTH{1'b0}};
        else if (timer_en)
            cnt_reg <= (cnt_reg == max_count) ? {CNT_WIDTH{1'b0}} : cnt_reg + 1'b1;
    end
    assign counter_val = cnt_reg;
    assign timer_done = (cnt_reg == max_count) && timer_en;
endmodule