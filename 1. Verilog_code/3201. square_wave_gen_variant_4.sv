//SystemVerilog
module square_wave_gen #(
    parameter COUNTER_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [COUNTER_WIDTH-1:0] period,
    output reg out
);
    reg [COUNTER_WIDTH-1:0] counter;
    wire period_reached;
    
    assign period_reached = (counter == period - 1);
    
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0;
            out <= 0;
        end else begin
            counter <= period_reached ? 0 : counter + 1;
            out <= period_reached ? ~out : out;
        end
    end
endmodule