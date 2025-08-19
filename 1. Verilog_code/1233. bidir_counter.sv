module bidir_counter #(parameter N = 4) (
    input wire clock, clear, load, up_down,
    input wire [N-1:0] data_in,
    output reg [N-1:0] count
);
    always @(posedge clock) begin
        if (clear)
            count <= {N{1'b0}};
        else if (load)
            count <= data_in;
        else
            count <= up_down ? count + 1'b1 : count - 1'b1;
    end
endmodule