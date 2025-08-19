//SystemVerilog
module decoder_hier #(parameter NUM_SLAVES=4) (
    input [7:0] addr,
    output reg [3:0] high_decode,
    output reg [3:0] low_decode
);

    // Pipeline stage 1: Address range validation
    wire addr_valid;
    assign addr_valid = (addr[7:4] < NUM_SLAVES);

    // Pipeline stage 2: High decode generation
    reg [3:0] high_decode_pre;
    always @* begin
        case (addr[7:4])
            4'b0000: high_decode_pre = 4'b0001;
            4'b0001: high_decode_pre = 4'b0010;
            4'b0010: high_decode_pre = 4'b0100;
            4'b0011: high_decode_pre = 4'b1000;
            default: high_decode_pre = 4'b0000;
        endcase
    end

    // Pipeline stage 3: High decode finalization
    always @* begin
        high_decode = addr_valid ? high_decode_pre : 4'b0000;
    end

    // Pipeline stage 4: Low decode generation
    always @* begin
        case (addr[3:0])
            4'b0000: low_decode = 4'b0001;
            4'b0001: low_decode = 4'b0010;
            4'b0010: low_decode = 4'b0100;
            4'b0011: low_decode = 4'b1000;
            default: low_decode = 4'b0000;
        endcase
    end

endmodule