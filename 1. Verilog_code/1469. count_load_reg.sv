module count_load_reg(
    input clk, rst,
    input [7:0] load_val,
    input load, count_en,
    output reg [7:0] count
);
    always @(posedge clk) begin
        if (rst)
            count <= 8'h00;
        else if (load)
            count <= load_val;
        else if (count_en)
            count <= count + 1'b1;
    end
endmodule