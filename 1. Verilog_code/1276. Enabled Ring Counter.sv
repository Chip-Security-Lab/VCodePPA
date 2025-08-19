module enabled_ring_counter(
    input wire clock,
    input wire reset,
    input wire enable,
    output reg [3:0] count
);
    always @(posedge clock) begin
        if (reset)
            count <= 4'b0001;
        else if (enable)
            count <= {count[2:0], count[3]};
    end
endmodule