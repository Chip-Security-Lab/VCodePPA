//SystemVerilog
module reg_out_shifter (
    input clk, reset_n,
    input serial_in,
    output reg serial_out
);
    reg [2:0] shift;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift <= 3'b000;
            serial_out <= 1'b0;
        end
        else begin
            shift <= {serial_in, shift[2:1]};
            serial_out <= shift[0];
        end
    end
endmodule