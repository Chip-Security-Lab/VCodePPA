//SystemVerilog
module dual_shifter (
    input CLK, nRST,
    input data_a, data_b,
    output [3:0] out_a, out_b
);
    reg [3:0] shifter_a, shifter_b;
    
    always @(posedge CLK) begin
        if (!nRST) begin
            shifter_a <= 4'b0000;
            shifter_b <= 4'b0000;
        end
        else begin
            shifter_a <= {shifter_a[2:0], data_a};
            shifter_b <= {data_b, shifter_b[3:1]};
        end
    end
    
    assign out_a = shifter_a;
    assign out_b = shifter_b;
endmodule