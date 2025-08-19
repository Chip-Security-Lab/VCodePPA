//SystemVerilog
module decoder_cascade (
    input en_in,
    input [2:0] addr,
    output [7:0] decoded,
    output en_out
);
    // Direct connections eliminate unnecessary intermediate signals
    assign en_out = en_in;
    // One-hot decoder implemented directly in top module
    assign decoded = en_in ? (8'b1 << addr) : 8'h0;
endmodule

// Module below are kept for reference but are no longer used
// Their functionality has been integrated into the top module

module enable_generator (
    input en_in,
    output reg enable
);
    always @(*) begin
        enable = en_in;
    end
endmodule

module address_decoder (
    input enable,
    input [2:0] addr,
    output reg [7:0] decoded
);
    always @(*) begin
        if (enable) begin
            decoded = 8'b0;
            decoded[addr] = 1'b1;
        end else begin
            decoded = 8'h0;
        end
    end
endmodule

module output_handler (
    input enable,
    input [7:0] decoded_internal,
    output reg [7:0] decoded,
    output reg en_out
);
    always @(*) begin
        decoded = decoded_internal;
        en_out = enable;
    end
endmodule