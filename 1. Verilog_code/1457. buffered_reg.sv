module buffered_reg(
    input clk, n_rst,
    input [15:0] data_i,
    input load,
    output reg [15:0] data_o
);
    reg [15:0] buffer;
    
    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            buffer <= 16'h0;
            data_o <= 16'h0;
        end else if (load) begin
            buffer <= data_i;
            data_o <= buffer;
        end
    end
endmodule