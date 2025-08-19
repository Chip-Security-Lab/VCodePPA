//SystemVerilog
//IEEE 1364-2005 Verilog
module compare_match_timer (
    input i_clock, i_nreset, i_enable,
    input [23:0] i_compare,
    output reg o_match,
    output [23:0] o_counter
);
    // Stage 1: Counter logic and comparison in single stage
    reg [23:0] timer_cnt;
    reg valid;
    
    // Combined stage: Counter and comparison logic
    always @(posedge i_clock) begin
        if (!i_nreset) begin
            timer_cnt <= 24'h000000;
            valid <= 1'b0;
            o_match <= 1'b0;
        end
        else begin
            if (i_enable) begin
                timer_cnt <= timer_cnt + 24'h000001;
                valid <= 1'b1;
            end
            else begin
                valid <= 1'b0;
            end
            
            // Match detection integrated into same stage
            o_match <= (timer_cnt == i_compare) && valid;
        end
    end
    
    // Output counter value
    assign o_counter = timer_cnt;
    
endmodule