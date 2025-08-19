//SystemVerilog
module decoder_hier #(parameter NUM_SLAVES=4) (
    input [7:0] addr,
    output reg [3:0] high_decode,
    output reg [3:0] low_decode
);

// Pipeline stage 1: Address split and validation
reg [3:0] high_addr_reg;
reg [3:0] low_addr_reg;
reg high_addr_valid;

always @* begin
    high_addr_reg = addr[7:4];
    low_addr_reg = addr[3:0];
    high_addr_valid = (high_addr_reg < NUM_SLAVES);
end

// Pipeline stage 2: Barrel shifters
reg [3:0] high_shift_result;
reg [3:0] low_shift_result;

always @* begin
    // High address barrel shifter
    case (high_addr_reg)
        4'd0: high_shift_result = 4'b0001;
        4'd1: high_shift_result = 4'b0010;
        4'd2: high_shift_result = 4'b0100;
        4'd3: high_shift_result = 4'b1000;
        default: high_shift_result = 4'b0000;
    endcase

    // Low address barrel shifter
    case (low_addr_reg)
        4'd0: low_shift_result = 4'b0001;
        4'd1: low_shift_result = 4'b0010;
        4'd2: low_shift_result = 4'b0100;
        4'd3: low_shift_result = 4'b1000;
        default: low_shift_result = 4'b0000;
    endcase
end

// Pipeline stage 3: Final decode outputs
always @* begin
    high_decode = high_addr_valid ? high_shift_result : 4'b0;
    low_decode = low_shift_result;
end

endmodule