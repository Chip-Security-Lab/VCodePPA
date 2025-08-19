//SystemVerilog
module dual_shifter (
    input CLK, nRST,
    input data_a, data_b,
    output [3:0] out_a, out_b
);
    reg [2:0] shifter_a_reg;
    reg data_a_reg;
    reg [3:1] shifter_b_reg;
    reg data_b_reg;
    
    always @(posedge CLK) begin
        if (!nRST) begin
            shifter_a_reg <= 3'b000;
            data_a_reg <= 1'b0;
            shifter_b_reg <= 3'b000;
            data_b_reg <= 1'b0;
        end else begin
            shifter_a_reg <= shifter_a_reg[1:0];
            data_a_reg <= data_a;
            shifter_b_reg <= shifter_b_reg[3:2];
            data_b_reg <= data_b;
        end
    end
    
    assign out_a = {shifter_a_reg, data_a_reg};
    assign out_b = {data_b_reg, shifter_b_reg};
endmodule