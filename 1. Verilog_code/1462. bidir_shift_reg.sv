module bidir_shift_reg(
    input clock, clear,
    input [7:0] p_data,
    input load, shift, dir, s_in,
    output reg [7:0] q
);
    always @(posedge clock) begin
        if (clear)
            q <= 8'b0;
        else if (load)
            q <= p_data;
        else if (shift) begin
            if (dir)  // Right shift
                q <= {s_in, q[7:1]};
            else      // Left shift
                q <= {q[6:0], s_in};
        end
    end
endmodule