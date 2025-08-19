//SystemVerilog
module async_combo_timer #(parameter CNT_WIDTH = 16)(
    input wire clock, reset, timer_en,
    input wire [CNT_WIDTH-1:0] max_count,
    output wire [CNT_WIDTH-1:0] counter_val,
    output wire timer_done
);
    reg [CNT_WIDTH-1:0] cnt_reg;
    reg [CNT_WIDTH-1:0] cnt_buf1, cnt_buf2;  // Buffer registers for cnt_reg
    reg timer_en_buf;                        // Buffer for timer_en signal
    reg cnt_eq_max;                          // Registered comparison result
    
    // Main counter logic - converted to case statement
    always @(posedge clock) begin
        case ({reset, timer_en_buf, cnt_eq_max})
            3'b100, 3'b101, 3'b110, 3'b111: 
                cnt_reg <= {CNT_WIDTH{1'b0}}; // Reset cases
            3'b010: 
                cnt_reg <= cnt_reg + 1'b1;    // Counting case
            3'b011: 
                cnt_reg <= {CNT_WIDTH{1'b0}}; // Counter reached max
            default: 
                cnt_reg <= cnt_reg;           // Hold value
        endcase
    end
    
    // Buffer registers to reduce fanout of cnt_reg
    always @(posedge clock) begin
        cnt_buf1 <= cnt_reg;
        cnt_buf2 <= cnt_reg;
        timer_en_buf <= timer_en;
        cnt_eq_max <= (cnt_reg == max_count);
    end
    
    // Use buffered counter values for outputs
    assign counter_val = cnt_buf1;
    assign timer_done = cnt_eq_max && timer_en_buf;
endmodule