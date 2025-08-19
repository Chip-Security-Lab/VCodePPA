//SystemVerilog
module BitPacker #(
    parameter IN_W = 32,
    parameter OUT_W = 64,
    parameter EFF_BITS = 8
) (
    input wire clk,
    input wire ce,
    input wire [IN_W-1:0] din,
    output reg [OUT_W-1:0] dout,
    output reg valid
);

    // Optimized stage registers
    reg [OUT_W-1:0] buffer_stage1;
    reg [5:0] bit_ptr_stage1;
    reg [EFF_BITS-1:0] data_stage1;
    reg valid_stage1;
    reg ce_stage1;

    reg [OUT_W-1:0] buffer_stage2;
    reg [5:0] bit_ptr_stage2;
    reg valid_stage2;
    
    // Compute next bit pointer value once
    wire [5:0] next_bit_ptr = bit_ptr_stage2 + EFF_BITS;
    // Pre-calculate output validity condition
    wire will_be_valid = next_bit_ptr >= OUT_W;
    
    // Pipeline stage 1: Input capture and shift calculation
    always @(posedge clk) begin
        if (ce) begin
            data_stage1 <= din[EFF_BITS-1:0];
            buffer_stage1 <= buffer_stage2;
            bit_ptr_stage1 <= bit_ptr_stage2;
            valid_stage1 <= will_be_valid;
            ce_stage1 <= ce;
        end
    end

    // Pre-compute shifted data for stage 2
    wire [OUT_W-1:0] shifted_data = {{(OUT_W-EFF_BITS){1'b0}}, data_stage1} << bit_ptr_stage1;
    
    // Pipeline stage 2: Buffer update and output generation
    always @(posedge clk) begin
        if (ce_stage1) begin
            // Use pre-computed shifted data
            buffer_stage2 <= buffer_stage1 | shifted_data;
            bit_ptr_stage2 <= bit_ptr_stage1 + EFF_BITS;
            valid_stage2 <= valid_stage1;
        end
    end

    // Output stage with synchronous reset
    always @(posedge clk) begin
        if (valid_stage2) begin
            dout <= buffer_stage2;
            valid <= 1'b1;
            buffer_stage2 <= {OUT_W{1'b0}};
            bit_ptr_stage2 <= 6'b0;
        end else begin
            valid <= 1'b0;
        end
    end

    // Initialize registers
    initial begin
        buffer_stage1 = {OUT_W{1'b0}};
        bit_ptr_stage1 = 6'b0;
        data_stage1 = {EFF_BITS{1'b0}};
        valid_stage1 = 1'b0;
        ce_stage1 = 1'b0;
        
        buffer_stage2 = {OUT_W{1'b0}};
        bit_ptr_stage2 = 6'b0;
        valid_stage2 = 1'b0;
        
        dout = {OUT_W{1'b0}};
        valid = 1'b0;
    end

endmodule