//SystemVerilog
module config_reg_decoder #(
    parameter REGISTERED_OUTPUT = 1
)(
    input clk,
    input [1:0] addr,
    output [3:0] dec_out
);
    // Pipeline stage signals
    reg [3:0] decode_stage;
    reg [3:0] output_stage;
    
    // Decode logic
    always @(*) begin
        case(addr)
            2'b00: decode_stage = 4'b0001;
            2'b01: decode_stage = 4'b0010;
            2'b10: decode_stage = 4'b0100;
            2'b11: decode_stage = 4'b1000;
            default: decode_stage = 4'b0000;
        endcase
    end
    
    // Pipeline register
    always @(posedge clk) begin
        output_stage <= decode_stage;
    end
    
    // Output selection
    assign dec_out = REGISTERED_OUTPUT ? output_stage : decode_stage;
endmodule