//SystemVerilog
module async_div #(parameter DIV=4) (
    input  wire clk_in,
    output reg  clk_out
);
    // Sequential logic registers
    reg [3:0] cnt;
    
    // Combinational logic signals
    wire clk_out_next;
    
    // Combinational logic block
    assign clk_out_next = (DIV <= 4) ? |cnt[DIV-1:1] : |cnt[3:1];
    
    // Sequential logic block
    always @(posedge clk_in) begin
        cnt <= cnt + 1'b1;
        clk_out <= clk_out_next;
    end
endmodule