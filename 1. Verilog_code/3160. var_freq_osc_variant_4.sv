//SystemVerilog
module var_freq_osc(
    input main_clk,
    input rst_n,
    input [7:0] freq_sel,
    output reg out_clk
);
    reg [15:0] counter;
    wire [15:0] max_count;
    wire counter_full;
    
    assign max_count = {8'h00, ~freq_sel} + 16'd1;
    assign counter_full = (counter >= max_count - 1);
    
    always @(posedge main_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'd0;
            out_clk <= 1'b0;
        end
        else if (counter_full) begin
            counter <= 16'd0;
            out_clk <= ~out_clk;
        end
        else begin
            counter <= counter + 1'b1;
        end
    end
endmodule