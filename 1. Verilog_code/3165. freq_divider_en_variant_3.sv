//SystemVerilog
module freq_divider_en(
    input i_Clock,
    input i_Enable,
    input i_Reset,
    output reg o_Clock
);
    reg [2:0] r_Count;
    
    always @(posedge i_Clock or posedge i_Reset) begin
        if (i_Reset) begin
            r_Count <= 3'd0;
            o_Clock <= 1'b0;
        end else if (i_Enable) begin
            if (r_Count == 3'd7) begin
                r_Count <= 3'd0;
                o_Clock <= ~o_Clock;
            end else
                r_Count <= r_Count + 1'b1;
        end
    end
endmodule