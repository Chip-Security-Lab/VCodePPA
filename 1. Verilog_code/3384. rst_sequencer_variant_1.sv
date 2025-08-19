//SystemVerilog
module rst_sequencer(
    input wire clk,
    input wire rst_trigger,
    output reg [3:0] rst_stages
);
    reg [1:0] counter;
    
    always @(posedge clk) begin
        if (rst_trigger) begin
            counter <= 2'd0;
            rst_stages <= 4'b1111;
        end else if (counter < 2'd3) begin
            counter <= counter + 2'd1;
            rst_stages <= 4'b0111 >> counter;
        end else begin
            rst_stages <= 4'b0000;
        end
    end
endmodule