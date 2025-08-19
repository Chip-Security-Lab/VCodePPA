//SystemVerilog
module rom_clkdiv #(parameter MAX=50000000)(
    input clk,
    output reg clk_out = 1'b0
);
    localparam COUNTER_WIDTH = $clog2(MAX);
    reg [COUNTER_WIDTH-1:0] counter = 0;
    
    always @(posedge clk) begin
        if(counter == MAX-1) begin
            counter <= 0;
            clk_out <= ~clk_out;
        end else begin
            counter <= counter + 1'b1;
        end
    end
endmodule