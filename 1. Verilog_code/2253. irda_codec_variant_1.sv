//SystemVerilog
module irda_codec #(parameter DIV=16) (
    input clk, din,
    output reg dout
);
    reg [7:0] pulse_cnt;
    
    always @(posedge clk) begin
        case(pulse_cnt)
            (DIV*3/16): dout <= !din;
            DIV: begin
                dout <= 1'b1;
                pulse_cnt <= 0;
            end
            default: pulse_cnt <= pulse_cnt + 1;
        endcase
    end
endmodule