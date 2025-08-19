//SystemVerilog
module circular_shift_buffer #(parameter SIZE = 8, WIDTH = 4) (
    input wire clk, reset, write_en,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] buffer [0:SIZE-1];
    reg [$clog2(SIZE)-1:0] read_ptr, write_ptr;
    reg [$clog2(SIZE)-1:0] read_ptr_stage1, write_ptr_stage1;
    reg [$clog2(SIZE)-1:0] read_ptr_stage2, write_ptr_stage2;
    
    // Stage 1: Pointer calculation
    wire [$clog2(SIZE)-1:0] next_write_ptr = (write_ptr == SIZE-1) ? 0 : write_ptr + 1;
    wire [$clog2(SIZE)-1:0] next_read_ptr = (read_ptr == SIZE-1) ? 0 : read_ptr + 1;
    
    // Stage 1: Register pointer updates
    always @(posedge clk) begin
        if (reset) begin
            read_ptr_stage1 <= {$clog2(SIZE){1'b0}};
            write_ptr_stage1 <= {$clog2(SIZE){1'b0}};
        end else if (write_en) begin
            read_ptr_stage1 <= next_read_ptr;
            write_ptr_stage1 <= next_write_ptr;
        end
    end
    
    // Stage 2: Buffer write and pointer update
    always @(posedge clk) begin
        if (reset) begin
            read_ptr_stage2 <= {$clog2(SIZE){1'b0}};
            write_ptr_stage2 <= {$clog2(SIZE){1'b0}};
        end else begin
            read_ptr_stage2 <= read_ptr_stage1;
            write_ptr_stage2 <= write_ptr_stage1;
            if (write_en) begin
                buffer[write_ptr] <= data_in;
            end
        end
    end
    
    // Stage 3: Final pointer update
    always @(posedge clk) begin
        if (reset) begin
            read_ptr <= {$clog2(SIZE){1'b0}};
            write_ptr <= {$clog2(SIZE){1'b0}};
        end else begin
            read_ptr <= read_ptr_stage2;
            write_ptr <= write_ptr_stage2;
        end
    end
    
    // Stage 4: Data output registration
    reg [WIDTH-1:0] data_out_reg;
    always @(posedge clk) begin
        data_out_reg <= buffer[read_ptr];
    end
    
    assign data_out = data_out_reg;
endmodule