module bidir_ring_counter(
    input wire clk,
    input wire rst,
    input wire dir, // 0: right, 1: left
    output reg [3:0] q_out
);
    always @(posedge clk) begin
        if (rst)
            q_out <= 4'b0001;
        else if (dir)
            q_out <= {q_out[2:0], q_out[3]}; // Right shift
        else
            q_out <= {q_out[0], q_out[3:1]}; // Left shift
    end
endmodule