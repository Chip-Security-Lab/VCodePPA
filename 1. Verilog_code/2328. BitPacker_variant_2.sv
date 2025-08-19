//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: BitPacker
// Description: Top level module that packs input bits into wider output words
///////////////////////////////////////////////////////////////////////////////
module BitPacker #(
    parameter IN_W = 32,     // Input data width
    parameter OUT_W = 64,    // Output data width 
    parameter EFF_BITS = 8,  // Number of effective bits to pack
    parameter PTR_WIDTH = $clog2(OUT_W)  // Bit pointer width, calculated automatically
) (
    input wire clk,          // System clock
    input wire ce,           // Clock enable
    input wire [IN_W-1:0] din,    // Input data
    output wire [OUT_W-1:0] dout,  // Packed output data
    output wire valid         // Output valid flag
);
    // Internal signals for connecting modules
    wire [OUT_W-1:0] buffer_data;
    wire [PTR_WIDTH-1:0] current_bit_ptr;
    wire [OUT_W-1:0] shifted_din_pipe;
    wire [PTR_WIDTH-1:0] updated_bit_ptr_pipe;
    wire buffer_valid;

    // Data shift module instance with pipelined output
    DataShifter #(
        .IN_W(IN_W),
        .OUT_W(OUT_W),
        .EFF_BITS(EFF_BITS),
        .PTR_WIDTH(PTR_WIDTH)
    ) u_data_shifter (
        .clk(clk),
        .ce(ce),
        .din(din),
        .bit_ptr(current_bit_ptr),
        .shifted_data(shifted_din_pipe),
        .next_bit_ptr(updated_bit_ptr_pipe)
    );

    // Buffer control module instance
    BufferController #(
        .OUT_W(OUT_W),
        .EFF_BITS(EFF_BITS),
        .PTR_WIDTH(PTR_WIDTH)
    ) u_buffer_controller (
        .clk(clk),
        .ce(ce),
        .shifted_data(shifted_din_pipe),
        .current_bit_ptr(current_bit_ptr),
        .next_bit_ptr(updated_bit_ptr_pipe),
        .buffer_data(buffer_data),
        .buffer_valid(buffer_valid)
    );

    // Output stage module instance
    OutputStage #(
        .OUT_W(OUT_W)
    ) u_output_stage (
        .clk(clk),
        .ce(ce),
        .buffer_data(buffer_data),
        .buffer_valid(buffer_valid),
        .dout(dout),
        .valid(valid)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: DataShifter
// Description: Shifts input data by the current bit pointer position
//              Pipelined architecture with optimized shift operation
///////////////////////////////////////////////////////////////////////////////
module DataShifter #(
    parameter IN_W = 32,
    parameter OUT_W = 64,
    parameter EFF_BITS = 8,
    parameter PTR_WIDTH = $clog2(OUT_W)
) (
    input wire clk,
    input wire ce,
    input wire [IN_W-1:0] din,
    input wire [PTR_WIDTH-1:0] bit_ptr,
    output reg [OUT_W-1:0] shifted_data,
    output reg [PTR_WIDTH-1:0] next_bit_ptr
);
    // Extract effective bits from input - create a mask for valid bits
    wire [EFF_BITS-1:0] effective_bits = din & {EFF_BITS{1'b1}};
    
    // Pipeline registers
    reg [EFF_BITS-1:0] effective_bits_reg;
    reg [PTR_WIDTH-1:0] bit_ptr_reg;
    reg [PTR_WIDTH-1:0] next_bit_ptr_stage1;
    
    // First pipeline stage - register inputs
    always @(posedge clk) begin
        if (ce) begin
            effective_bits_reg <= effective_bits;
            bit_ptr_reg <= bit_ptr;
            // Pre-compute next bit pointer value
            next_bit_ptr_stage1 <= bit_ptr + EFF_BITS;
        end
    end
    
    // Second pipeline stage - perform the shift operation
    // Use optimized shift operation that reduces the critical path
    always @(posedge clk) begin
        if (ce) begin
            // Optimized shift operation using concatenation and truncation
            shifted_data <= {{(OUT_W-EFF_BITS){1'b0}}, effective_bits_reg} << bit_ptr_reg;
            next_bit_ptr <= next_bit_ptr_stage1;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: BufferController
// Description: Maintains and updates the bit buffer with new data
///////////////////////////////////////////////////////////////////////////////
module BufferController #(
    parameter OUT_W = 64,
    parameter EFF_BITS = 8,
    parameter PTR_WIDTH = $clog2(OUT_W)
) (
    input wire clk,
    input wire ce,
    input wire [OUT_W-1:0] shifted_data,
    output reg [PTR_WIDTH-1:0] current_bit_ptr = 0,
    input wire [PTR_WIDTH-1:0] next_bit_ptr,
    output reg [OUT_W-1:0] buffer_data = 0,
    output reg buffer_valid
);
    // Optimized comparison logic
    wire threshold_reached = (next_bit_ptr >= OUT_W);
    
    // First stage: calculate if buffer will have enough bits
    reg pre_buffer_valid;
    
    always @(posedge clk) begin
        if (ce) begin
            pre_buffer_valid <= threshold_reached;
        end
    end
    
    // Second stage: update buffer and bit pointer
    always @(posedge clk) begin
        if (ce) begin
            // Update valid flag
            buffer_valid <= pre_buffer_valid;
            
            // Merge new data with existing buffer using bitwise OR
            buffer_data <= buffer_data | shifted_data;
            
            // Conditional update based on pre-calculated valid flag
            if (pre_buffer_valid) begin
                buffer_data <= 0;
                current_bit_ptr <= 0;
            end else begin
                current_bit_ptr <= next_bit_ptr;
            end
        end
    end
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: OutputStage
// Description: Manages the final output data and valid signal
///////////////////////////////////////////////////////////////////////////////
module OutputStage #(
    parameter OUT_W = 64
) (
    input wire clk,
    input wire ce,
    input wire [OUT_W-1:0] buffer_data,
    input wire buffer_valid,
    output reg [OUT_W-1:0] dout = 0,
    output reg valid = 0
);
    // Intermediate pipeline registers
    reg [OUT_W-1:0] buffer_data_pipe;
    reg buffer_valid_pipe;
    
    // First pipeline stage - register intermediate values
    always @(posedge clk) begin
        if (ce) begin
            buffer_data_pipe <= buffer_data;
            buffer_valid_pipe <= buffer_valid;
        end
    end
    
    // Second pipeline stage - produce final output
    always @(posedge clk) begin
        if (ce) begin
            valid <= buffer_valid_pipe;
            // Optimized conditional assignment using bitwise AND
            dout <= buffer_data_pipe & {OUT_W{buffer_valid_pipe}};
        end
    end
    
endmodule