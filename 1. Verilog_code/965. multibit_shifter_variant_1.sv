//SystemVerilog
module multibit_shifter (
    input wire clk,
    input wire reset,
    input wire [1:0] data_in,
    output reg [1:0] data_out
);
    reg [3:0] shift_reg; // 优化寄存器位宽
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_reg <= 4'b0000;
            data_out <= 2'b00;
        end else begin
            shift_reg <= {data_in, shift_reg[3:2]};
            data_out <= shift_reg[1:0];
        end
    end
endmodule