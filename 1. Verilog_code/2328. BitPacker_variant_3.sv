//SystemVerilog
module BitPacker #(
    parameter IN_W = 32,
    parameter OUT_W = 64,
    parameter EFF_BITS = 8
)(
    input wire clk,
    input wire ce,
    input wire [IN_W-1:0] din,
    output reg [OUT_W-1:0] dout,
    output reg valid
);

    // Stage 1: Data preparation and buffer update
    reg [OUT_W-1:0] buffer_stage1 = 0;
    reg [5:0] bit_ptr_stage1 = 0;
    reg valid_stage1 = 0;
    reg [OUT_W-1:0] next_buffer;
    reg [5:0] next_bit_ptr;
    reg next_valid;
    
    // Stage 2: Output generation
    reg [OUT_W-1:0] buffer_stage2 = 0;
    reg valid_stage2 = 0;
    
    // Combinational logic for stage 1
    always @(*) begin
        next_buffer = buffer_stage1 | ({OUT_W{1'b0}} | din[EFF_BITS-1:0]) << bit_ptr_stage1;
        next_bit_ptr = bit_ptr_stage1 + EFF_BITS;
        next_valid = (bit_ptr_stage1 + EFF_BITS) >= OUT_W;
    end
    
    // Pipeline stage 1 - Process input and update buffer
    always @(posedge clk) begin
        if (ce) begin
            buffer_stage1 <= next_valid ? {OUT_W{1'b0}} : next_buffer;
            bit_ptr_stage1 <= next_valid ? 0 : next_bit_ptr;
            valid_stage1 <= next_valid;
        end
    end
    
    // Pipeline stage 2 - Prepare output
    always @(posedge clk) begin
        if (ce) begin
            buffer_stage2 <= next_valid ? next_buffer : buffer_stage2;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output assignment
    always @(posedge clk) begin
        if (ce) begin
            dout <= valid_stage2 ? buffer_stage2 : 0;
            valid <= valid_stage2;
        end
    end

endmodule