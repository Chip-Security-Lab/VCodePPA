//SystemVerilog
module TimeoutArbiter #(parameter T=10) (
    input clk, rst,
    input req,
    output reg grant
);
reg [7:0] timeout;
reg [7:0] timeout_next;
reg [7:0] timeout_comp;

always @(*) begin
    timeout_comp = ~timeout + 1'b1;  // 2's complement
    timeout_next = timeout + timeout_comp;  // subtraction using 2's complement
end

always @(posedge clk) begin
    case({rst, timeout == 0})
        2'b10: begin  // rst asserted
            grant <= 0;
            timeout <= 0;
        end
        2'b01: begin  // timeout == 0
            grant <= req;
            timeout <= (req) ? T : 0;
        end
        default: begin  // timeout != 0
            timeout <= timeout_next;
        end
    endcase
end
endmodule