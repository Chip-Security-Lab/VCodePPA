//SystemVerilog
`timescale 1ns / 1ps
module async_combo_timer #(parameter CNT_WIDTH = 16)(
    input wire clock, reset, timer_en,
    input wire [CNT_WIDTH-1:0] max_count,
    output wire [CNT_WIDTH-1:0] counter_val,
    output wire timer_done
);
    // Main counter register
    reg [CNT_WIDTH-1:0] cnt_reg;
    
    // Buffered counter registers for high fan-out reduction
    reg [CNT_WIDTH-1:0] cnt_buff1, cnt_buff2;
    
    // Counter compare result register
    reg cnt_eq_max;
    
    // Counter update logic
    always @(posedge clock) begin
        if (reset) cnt_reg <= {CNT_WIDTH{1'b0}};
        else if (timer_en)
            cnt_reg <= (cnt_eq_max) ? {CNT_WIDTH{1'b0}} : cnt_reg + 1'b1;
    end
    
    // Buffer registers for high fan-out signal cnt_reg
    always @(posedge clock) begin
        cnt_buff1 <= cnt_reg;
        cnt_buff2 <= cnt_reg;
    end
    
    // Comparison logic with registered output
    always @(posedge clock) begin
        cnt_eq_max <= (cnt_buff1 == max_count);
    end
    
    // Output assignments using buffered signals
    assign counter_val = cnt_buff1;
    assign timer_done = cnt_eq_max && timer_en;
endmodule