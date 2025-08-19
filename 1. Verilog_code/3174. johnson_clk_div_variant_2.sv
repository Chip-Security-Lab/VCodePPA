//SystemVerilog
module johnson_clk_div(
    input clk_i,
    input rst_i,
    input valid_i,
    output reg ready_o,
    output reg [3:0] clk_o
);
    reg [3:0] johnson_cnt;
    reg [3:0] clk_reg;
    reg valid_pending;
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            johnson_cnt <= 4'b0000;
            clk_reg <= 4'b0000;
            ready_o <= 1'b1;
            valid_pending <= 1'b0;
        end else begin
            // Johnson counter always runs
            johnson_cnt <= {~johnson_cnt[0], johnson_cnt[3:1]};
            
            if (valid_i && ready_o) begin
                // Data transfer occurs when valid and ready are both high
                clk_reg <= johnson_cnt;
                valid_pending <= 1'b0;
            end else if (valid_i) begin
                // If valid but not ready, mark that we have a pending transaction
                valid_pending <= 1'b1;
                ready_o <= 1'b0;
            end else if (valid_pending) begin
                // Finish the pending transaction in the next cycle
                clk_reg <= johnson_cnt;
                valid_pending <= 1'b0;
                ready_o <= 1'b1;
            end else begin
                // No transaction, stay ready
                ready_o <= 1'b1;
            end
        end
    end
    
    assign clk_o = clk_reg;
endmodule