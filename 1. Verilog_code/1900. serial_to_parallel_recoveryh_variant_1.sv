//SystemVerilog
module serial_to_parallel_recovery #(
    parameter WIDTH = 8
)(
    input  wire           bit_clk,
    input  wire           reset,
    input  wire           serial_in,
    input  wire           frame_sync,
    output wire [WIDTH-1:0] parallel_out,
    output wire           data_valid
);
    // Internal registers with optimized pipeline structure
    reg           serial_data_r;
    reg [WIDTH-1:0] shift_reg;
    reg [3:0]      bit_count_r;
    reg            word_complete_r;
    reg            data_valid_r;
    reg [WIDTH-1:0] parallel_out_r;
    
    // Pre-compute next bit count to reduce critical path
    wire [3:0] next_bit_count = (bit_count_r == WIDTH-1) ? 4'h0 : bit_count_r + 4'h1;
    wire       next_word_complete = (bit_count_r == WIDTH-1);
    
    // Combined stage for input capture and bit counting with reduced logic depth
    always @(posedge bit_clk or posedge reset) begin
        if (reset) begin
            serial_data_r <= 1'b0;
            bit_count_r <= 4'h0;
            word_complete_r <= 1'b0;
        end else begin
            serial_data_r <= serial_in;
            
            if (frame_sync) begin
                bit_count_r <= 4'h0;
                word_complete_r <= 1'b0;
            end else begin
                bit_count_r <= next_bit_count;
                word_complete_r <= next_word_complete;
            end
        end
    end
    
    // Optimized shift register operations with simplified control logic
    always @(posedge bit_clk or posedge reset) begin
        if (reset) begin
            shift_reg <= {WIDTH{1'b0}};
        end else if (frame_sync) begin
            shift_reg <= {WIDTH{1'b0}};
        end else begin
            // Shift in serial data, MSB first
            shift_reg <= {shift_reg[WIDTH-2:0], serial_data_r};
        end
    end
    
    // Optimized output stage with reduced conditional logic
    always @(posedge bit_clk or posedge reset) begin
        if (reset) begin
            data_valid_r <= 1'b0;
            parallel_out_r <= {WIDTH{1'b0}};
        end else if (frame_sync) begin
            data_valid_r <= 1'b0;
            // Maintain current output during frame sync
        end else if (word_complete_r) begin
            // Load output and set valid flag when complete
            parallel_out_r <= shift_reg;
            data_valid_r <= 1'b1;
        end else begin
            data_valid_r <= 1'b0;
        end
    end
    
    // Output assignments
    assign parallel_out = parallel_out_r;
    assign data_valid = data_valid_r;
    
endmodule