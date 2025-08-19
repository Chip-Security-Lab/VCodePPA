//SystemVerilog
module decoder_pipelined (
    input clk,
    input rst_n,
    input valid_in,
    input [3:0] addr,
    output reg [15:0] decoded,
    output reg valid_out
);
    // Pipeline stage registers
    reg [3:0] addr_stage1;
    reg valid_stage1;
    reg [7:0] partial_decode_stage1;
    
    reg [7:0] partial_decode_stage2;
    reg addr_msb_stage2;
    reg valid_stage2;
    
    // Pre-computed decode values to reduce computation in critical path
    wire [7:0] decode_lut [0:7];
    assign decode_lut[0] = 8'b00000001;
    assign decode_lut[1] = 8'b00000010;
    assign decode_lut[2] = 8'b00000100;
    assign decode_lut[3] = 8'b00001000;
    assign decode_lut[4] = 8'b00010000;
    assign decode_lut[5] = 8'b00100000;
    assign decode_lut[6] = 8'b01000000;
    assign decode_lut[7] = 8'b10000000;
    
    // Stage 1: Register inputs and perform partial decoding using LUT
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            addr_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
            partial_decode_stage1 <= 8'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= valid_in;
            partial_decode_stage1 <= decode_lut[addr[2:0]];
        end
    end
    
    // Stage 2: Prepare for final stage, only pass necessary bits
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            partial_decode_stage2 <= 8'b0;
            addr_msb_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            partial_decode_stage2 <= partial_decode_stage1;
            addr_msb_stage2 <= addr_stage1[3];  // Only forward the MSB bit we need
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Final decoding with reduced complexity
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            decoded <= 16'b0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage2;
            
            // Use conditional assignment with balanced logic paths
            decoded <= addr_msb_stage2 ? {partial_decode_stage2, 8'b0} : {8'b0, partial_decode_stage2};
        end
    end
endmodule