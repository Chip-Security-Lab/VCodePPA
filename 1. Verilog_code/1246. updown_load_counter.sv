module updown_load_counter (
    input wire clk, rst_n, load, up_down,
    input wire [7:0] data_in,
    output reg [7:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 8'h00;
        else if (load)
            q <= data_in;
        else if (up_down)
            q <= q + 1'b1;
        else
            q <= q - 1'b1;
    end
endmodule