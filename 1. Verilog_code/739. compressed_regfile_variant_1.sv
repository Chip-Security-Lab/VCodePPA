//SystemVerilog
module compressed_regfile #(
    parameter PACKED_WIDTH = 16,
    parameter UNPACKED_WIDTH = 32
)(
    input clk,
    input wr_en,
    input [3:0] addr,
    input [PACKED_WIDTH-1:0] din,
    output reg [UNPACKED_WIDTH-1:0] dout
);

// Storage registers
reg [PACKED_WIDTH-1:0] storage [0:15];

// LUT initialization and update logic
always @(posedge clk) begin
    if (wr_en) begin
        storage[addr] <= din;
    end
end

// Output logic using a case statement for optimized comparison
always @(*) begin
    case (addr)
        4'd0: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[0]};
        4'd1: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[1]};
        4'd2: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[2]};
        4'd3: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[3]};
        4'd4: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[4]};
        4'd5: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[5]};
        4'd6: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[6]};
        4'd7: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[7]};
        4'd8: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[8]};
        4'd9: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[9]};
        4'd10: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[10]};
        4'd11: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[11]};
        4'd12: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[12]};
        4'd13: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[13]};
        4'd14: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[14]};
        4'd15: dout = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[15]};
        default: dout = {UNPACKED_WIDTH{1'b0}}; // Default case for safety
    endcase
end

endmodule