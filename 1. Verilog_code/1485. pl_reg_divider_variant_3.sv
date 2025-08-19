//SystemVerilog
module pl_reg_divider #(parameter W=4, DIV=4) (
    input clk, rst,
    input [W-1:0] data_in,
    output reg [W-1:0] data_out
);

    reg [DIV-1:0] counter;
    reg [W-1:0] data_in_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            data_in_reg <= 0;
        end
        else begin
            counter <= counter + 1;
            if (&counter) begin
                data_in_reg <= data_in;
            end
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 0;
        end
        else if (&counter) begin
            data_out <= data_in_reg;
        end
    end
    
endmodule