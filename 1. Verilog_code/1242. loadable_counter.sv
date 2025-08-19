module loadable_counter (
    input wire clk, rst, load, en,
    input wire [3:0] data,
    output reg [3:0] count
);
    always @(posedge clk) begin
        if (rst)
            count <= 4'b0000;
        else if (load)
            count <= data;
        else if (en)
            count <= count + 1'b1;
    end
endmodule