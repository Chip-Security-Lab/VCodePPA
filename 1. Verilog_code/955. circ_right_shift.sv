module circ_right_shift #(parameter BITS = 4) (
    input wire clk,
    input wire rst_n,
    input wire en,
    output wire [BITS-1:0] q
);
    reg [BITS-1:0] shifter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shifter <= {{BITS-1{1'b0}}, 1'b1};  // Initialize with one hot
        else if (en)
            shifter <= {shifter[0], shifter[BITS-1:1]};
    end
    
    assign q = shifter;
endmodule