//SystemVerilog
module window_div #(parameter L=5, H=12) (
    input clk, rst_n,
    output reg clk_out
);
    reg [7:0] cnt_r;
    
    always @(posedge clk) begin
        if(!rst_n) begin
            cnt_r <= 0;
            clk_out <= 0;
        end else begin
            cnt_r <= cnt_r + 1;
            // Output register moved forward - directly compute the window condition
            clk_out <= (cnt_r >= L) & (cnt_r <= H);
        end
    end
endmodule