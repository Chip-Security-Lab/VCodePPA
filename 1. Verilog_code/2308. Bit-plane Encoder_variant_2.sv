//SystemVerilog
module bitplane_encoder #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
)(
    input                  clk,
    input                  reset,
    input                  enable,
    input [WIDTH-1:0]      data_in,
    input                  data_valid,
    output reg             bit_out,
    output reg             bit_valid,
    output reg [2:0]       current_plane
);
    // Buffers and control signals
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] ptr;
    reg [2:0] plane;
    
    // Processing control signals
    reg processing;
    reg valid_pipeline;
    
    // Data extraction signals
    wire extracted_bit;
    
    // Assign the extracted bit directly from buffer using combinational logic
    assign extracted_bit = buffer[ptr][plane];
    
    // Input buffering and control logic (moved forward)
    always @(posedge clk) begin
        if (reset) begin
            ptr <= 0;
            plane <= 0;
            processing <= 0;
            valid_pipeline <= 0;
        end else if (enable) begin
            if (data_valid) begin
                // Buffer input data
                buffer[ptr] <= data_in;
                ptr <= (ptr == DEPTH-1) ? 0 : ptr + 1;
                valid_pipeline <= 1;
                processing <= 0;
            end else if (!processing) begin
                // Start bit plane processing
                processing <= 1;
                valid_pipeline <= 1;
                ptr <= 0;
            end else begin
                // Continue bit plane processing
                if (ptr == DEPTH-1) begin
                    ptr <= 0;
                    plane <= (plane == WIDTH-1) ? 0 : plane + 1;
                    processing <= (plane == WIDTH-1) ? 0 : 1;
                end else begin
                    ptr <= ptr + 1;
                end
                valid_pipeline <= processing;
            end
        end else begin
            valid_pipeline <= 0;
        end
    end
    
    // Output stage (retimed forward)
    always @(posedge clk) begin
        if (reset) begin
            bit_out <= 0;
            bit_valid <= 0;
            current_plane <= 0;
        end else if (enable) begin
            // Directly use the extracted bit value
            if (valid_pipeline && processing) begin
                bit_out <= extracted_bit;
                bit_valid <= 1;
            end else begin
                bit_valid <= 0;
            end
            
            // Register the current plane for output
            current_plane <= plane;
        end else begin
            bit_valid <= 0;
        end
    end
endmodule