//SystemVerilog
module decoder_gated #(WIDTH=3) (
    input wire clk,
    input wire clk_en,
    input wire [WIDTH-1:0] addr,
    output reg [7:0] decoded
);

    // Pipeline stage 1: Address decode
    reg [7:0] decode_stage1;
    
    // Pipeline stage 2: Clock gating
    reg [7:0] decode_stage2;
    
    // Decode logic - Stage 1
    always @(*) begin
        case (addr)
            3'b000: decode_stage1 = 8'b00000001;
            3'b001: decode_stage1 = 8'b00000010;
            3'b010: decode_stage1 = 8'b00000100;
            3'b011: decode_stage1 = 8'b00001000;
            3'b100: decode_stage1 = 8'b00010000;
            3'b101: decode_stage1 = 8'b00100000;
            3'b110: decode_stage1 = 8'b01000000;
            3'b111: decode_stage1 = 8'b10000000;
            default: decode_stage1 = 8'b0;
        endcase
    end

    // Clock gating logic - Stage 2
    always @(posedge clk) begin
        if (clk_en)
            decode_stage2 <= decode_stage1;
        else
            decode_stage2 <= decode_stage2;
    end

    // Output stage
    always @(posedge clk) begin
        decoded <= decode_stage2;
    end

endmodule