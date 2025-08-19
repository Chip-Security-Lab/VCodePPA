module jitter_clock(
    input clk_in,
    input rst,
    input [2:0] jitter_amount,
    input jitter_en,
    output reg clk_out
);
    reg [4:0] counter;
    reg [2:0] jitter;
    
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 5'd0;
            clk_out <= 1'b0;
            jitter <= 3'd0;
        end else begin
            jitter <= jitter_en ? {^counter, counter[1:0]} & jitter_amount : 3'd0;
            if (counter + jitter >= 5'd16) begin
                counter <= 5'd0;
                clk_out <= ~clk_out;
            end else
                counter <= counter + 5'd1;
        end
    end
endmodule
