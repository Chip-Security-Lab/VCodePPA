//SystemVerilog
module DoubleBufferTimer #(parameter DW=8) (
    input clk, rst_n,
    input [DW-1:0] next_period,
    output reg [DW-1:0] current
);
    reg [DW-1:0] buffer;
    
    always @(posedge clk) begin
        case (rst_n)
            1'b0: {current, buffer} <= 0;
            1'b1: begin
                case (current == 0)
                    1'b1: begin
                        current <= buffer;
                        buffer <= next_period;
                    end
                    1'b0: begin
                        current <= current - 1;
                    end
                endcase
            end
        endcase
    end
endmodule