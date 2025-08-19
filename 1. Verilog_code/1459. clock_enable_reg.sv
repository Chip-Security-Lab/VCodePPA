module clock_enable_reg(
    input clk, sync_reset,
    input [3:0] data_word,
    input clk_en, load,
    output reg [3:0] q_out
);
    always @(posedge clk) begin
        if (clk_en) begin
            if (sync_reset)
                q_out <= 4'b0;
            else if (load)
                q_out <= data_word;
        end
    end
endmodule