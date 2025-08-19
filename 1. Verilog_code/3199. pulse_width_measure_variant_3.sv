//SystemVerilog
module pulse_width_measure #(
    parameter COUNTER_WIDTH = 32
)(
    input clk,
    input pulse_in,
    output reg [COUNTER_WIDTH-1:0] width_count
);

reg last_state;
reg measuring;

always @(posedge clk) begin
    last_state <= pulse_in;
    
    case ({pulse_in, last_state, measuring})
        3'b100: begin  // rising edge
            measuring <= 1'b1;
            width_count <= {COUNTER_WIDTH{1'b0}};
        end
        3'b011: begin  // falling edge
            measuring <= 1'b0;
        end
        3'b111: begin  // measuring high
            width_count <= width_count + 1'b1;
        end
        default: begin
            measuring <= measuring;
            width_count <= width_count;
        end
    endcase
end

endmodule