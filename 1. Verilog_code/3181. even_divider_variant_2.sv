//SystemVerilog
module even_divider #(
    parameter DIV_WIDTH = 8,
    parameter DIV_VALUE = 10
)(
    input clk_in,
    input rst_n,
    output reg clk_out
);
    reg [DIV_WIDTH-1:0] counter;
    wire [DIV_WIDTH-1:0] half_div_value;
    
    assign half_div_value = DIV_VALUE >> 1;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter == DIV_VALUE-1) begin
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
            
            if (counter < half_div_value) begin
                clk_out <= 1'b0;
            end else begin
                clk_out <= 1'b1;
            end
        end
    end
endmodule