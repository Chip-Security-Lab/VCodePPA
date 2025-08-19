//SystemVerilog
module counter_sync_inc #(parameter WIDTH=4) (
    input clk, rst_n, en,
    output reg [WIDTH-1:0] cnt
);

reg en_reg;
reg [WIDTH-1:0] next_cnt;

// Register the enable signal
always @(posedge clk) begin
    if (!rst_n) begin
        en_reg <= 0;
    end 
    else begin
        en_reg <= en;
    end
end

// Pre-compute next counter value (combinational)
always @(*) begin
    if (en_reg)
        next_cnt = cnt + 1;
    else
        next_cnt = cnt;
end

// Update counter with pre-computed value
always @(posedge clk) begin
    if (!rst_n) begin
        cnt <= 0;
    end
    else begin
        cnt <= next_cnt;
    end
end

endmodule