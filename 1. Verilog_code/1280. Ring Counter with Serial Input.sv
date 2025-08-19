module serial_in_ring_counter(
    input wire clk,
    input wire rst,
    input wire ser_in,
    output reg [3:0] count
);
    always @(posedge clk) begin
        if (rst)
            count <= 4'b0001;
        else
            count <= {count[2:0], ser_in}; // Use serial input
    end
endmodule