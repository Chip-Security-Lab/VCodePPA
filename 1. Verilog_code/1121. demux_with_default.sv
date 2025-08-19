module demux_with_default (
    input wire data_in,                  // Input data
    input wire [2:0] sel_addr,           // Selection address
    output reg [6:0] outputs,            // Normal outputs
    output reg default_out               // Default output for invalid addresses
);
    always @(*) begin
        outputs = 7'b0;
        default_out = 1'b0;
        
        case (sel_addr)
            3'b000: outputs[0] = data_in;
            3'b001: outputs[1] = data_in;
            3'b010: outputs[2] = data_in;
            3'b011: outputs[3] = data_in;
            3'b100: outputs[4] = data_in;
            3'b101: outputs[5] = data_in;
            3'b110: outputs[6] = data_in;
            default: default_out = data_in; // For address 3'b111 or undefined
        endcase
    end
endmodule