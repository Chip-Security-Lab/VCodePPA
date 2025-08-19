module direction_ring_counter(
    input wire clk,
    input wire rst,
    input wire dir_sel, // Direction select
    output reg [3:0] q_out
);
    always @(posedge clk) begin
        if (rst)
            q_out <= 4'b0001;
        else if (dir_sel)
            q_out <= {q_out[0], q_out[3:1]}; // Shift right
        else
            q_out <= {q_out[2:0], q_out[3]}; // Shift left
    end
endmodule