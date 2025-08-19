//SystemVerilog
module odd_div_biedge #(parameter N=5) (
    input clk, rst_n,
    output reg clk_out
);

// Counter registers
reg [2:0] pos_cnt;
reg [2:0] neg_cnt;

// Internal signals for retimed logic
reg pos_toggle;
reg neg_toggle;
reg pos_out_pre;
reg neg_out_pre;

// Positive edge counter with retimed logic
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pos_cnt <= 0;
        pos_toggle <= 0;
        pos_out_pre <= 0;
    end else begin
        if(pos_cnt == N-1) begin
            pos_cnt <= 0;
            pos_toggle <= 1;
        end else begin
            pos_cnt <= pos_cnt + 1;
            pos_toggle <= 0;
        end
        
        // Retimed register moved before XOR operation
        if(pos_toggle)
            pos_out_pre <= ~pos_out_pre;
    end
end

// Negative edge counter with retimed logic
always @(negedge clk or negedge rst_n) begin
    if(!rst_n) begin
        neg_cnt <= 0;
        neg_toggle <= 0;
        neg_out_pre <= 0;
    end else begin
        if(neg_cnt == N-1) begin
            neg_cnt <= 0;
            neg_toggle <= 1;
        end else begin
            neg_cnt <= neg_cnt + 1;
            neg_toggle <= 0;
        end
        
        // Retimed register moved before XOR operation
        if(neg_toggle)
            neg_out_pre <= ~neg_out_pre;
    end
end

// Output registered to improve timing
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        clk_out <= 0;
    else
        clk_out <= pos_out_pre ^ neg_out_pre;
end

endmodule