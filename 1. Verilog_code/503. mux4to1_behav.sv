module mux4to1_behav(
    input [3:0] data,
    input [1:0] sel,
    output reg y
);
    always @(*) begin
        case(sel)
            2'b00: y = data[0];
            2'b01: y = data[1];
            2'b10: y = data[2];
            2'b11: y = data[3];
        endcase
    end
endmodule