module one_hot_counter (
    input wire clock, reset_n,
    output reg [7:0] one_hot
);
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            one_hot <= 8'b00000001;
        else
            one_hot <= {one_hot[6:0], one_hot[7]};
    end
endmodule