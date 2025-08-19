//SystemVerilog
module eth_packet_buffer #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 12,
    parameter DEPTH = 4096
) (
    input wire clk_write,
    input wire clk_read,
    input wire reset,
    input wire write_en,
    input wire read_en,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output wire full,
    output wire empty
);
    // Memory buffer
    reg [DATA_WIDTH-1:0] buffer [0:DEPTH-1];
    
    // Pointers management
    reg [ADDR_WIDTH-1:0] write_ptr_current, write_ptr_next;
    reg [ADDR_WIDTH-1:0] read_ptr_current, read_ptr_next;
    reg [ADDR_WIDTH:0] count_current, count_next;
    
    // Pre-registered control signals
    reg write_en_reg, read_en_reg;
    reg [DATA_WIDTH-1:0] data_in_reg;
    
    // Pipeline registers for critical path optimization
    reg [ADDR_WIDTH-1:0] write_ptr_inc, read_ptr_inc;
    reg write_ptr_wrap, read_ptr_wrap;
    reg empty_stage1, full_stage1;
    reg [ADDR_WIDTH:0] count_inc, count_dec;
    
    // Status signals - registered for better timing
    reg empty_reg, full_reg;
    assign empty = empty_reg;
    assign full = full_reg;
    
    // Status calculation pipeline stage 1
    always @(posedge clk_write or posedge reset) begin
        if (reset) begin
            empty_stage1 <= 1'b1;
            full_stage1 <= 1'b0;
        end else begin
            empty_stage1 <= (count_current == 0);
            full_stage1 <= (count_current == DEPTH);
        end
    end
    
    // Status signals final stage
    always @(posedge clk_write or posedge reset) begin
        if (reset) begin
            empty_reg <= 1'b1;
            full_reg <= 1'b0;
        end else begin
            empty_reg <= empty_stage1;
            full_reg <= full_stage1;
        end
    end
    
    // Input stage registering - move registers forward
    always @(posedge clk_write or posedge reset) begin
        if (reset) begin
            write_en_reg <= 1'b0;
            data_in_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            write_en_reg <= write_en && !full_reg;
            data_in_reg <= data_in;
        end
    end
    
    always @(posedge clk_read or posedge reset) begin
        if (reset) begin
            read_en_reg <= 1'b0;
        end else begin
            read_en_reg <= read_en && !empty_reg;
        end
    end
    
    // Pointer increment pipeline stage
    always @(posedge clk_write or posedge reset) begin
        if (reset) begin
            write_ptr_inc <= 0;
            write_ptr_wrap <= 1'b0;
        end else begin
            write_ptr_inc <= write_ptr_current + 1;
            write_ptr_wrap <= (write_ptr_current == DEPTH-1);
        end
    end
    
    always @(posedge clk_read or posedge reset) begin
        if (reset) begin
            read_ptr_inc <= 0;
            read_ptr_wrap <= 1'b0;
        end else begin
            read_ptr_inc <= read_ptr_current + 1;
            read_ptr_wrap <= (read_ptr_current == DEPTH-1);
        end
    end
    
    // Write pointer logic - pipelined for timing
    always @(posedge clk_write or posedge reset) begin
        if (reset) begin
            write_ptr_current <= 0;
        end else begin
            write_ptr_current <= write_ptr_next;
        end
    end
    
    always @(*) begin
        write_ptr_next = write_ptr_current;
        if (write_en_reg) begin
            write_ptr_next = write_ptr_wrap ? 0 : write_ptr_inc;
        end
    end
    
    // Read pointer logic - pipelined for timing
    always @(posedge clk_read or posedge reset) begin
        if (reset) begin
            read_ptr_current <= 0;
        end else begin
            read_ptr_current <= read_ptr_next;
        end
    end
    
    always @(*) begin
        read_ptr_next = read_ptr_current;
        if (read_en_reg) begin
            read_ptr_next = read_ptr_wrap ? 0 : read_ptr_inc;
        end
    end
    
    // Data output registering - two-stage pipeline for timing
    reg [DATA_WIDTH-1:0] data_out_pre;
    reg read_valid;
    
    always @(posedge clk_read or posedge reset) begin
        if (reset) begin
            data_out_pre <= {DATA_WIDTH{1'b0}};
            read_valid <= 1'b0;
        end else begin
            data_out_pre <= buffer[read_ptr_current];
            read_valid <= read_en && !empty_reg;
        end
    end
    
    always @(posedge clk_read or posedge reset) begin
        if (reset) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end else if (read_valid) begin
            data_out <= data_out_pre;
        end
    end
    
    // Memory write operation with registered inputs
    always @(posedge clk_write) begin
        if (write_en_reg) begin
            buffer[write_ptr_current] <= data_in_reg;
        end
    end
    
    // Counter increment/decrement pipeline registers
    always @(posedge clk_write or posedge reset) begin
        if (reset) begin
            count_inc <= 0;
            count_dec <= 0;
        end else begin
            count_inc <= count_current + 1;
            count_dec <= count_current - 1;
        end
    end
    
    // Counter logic with pipelined path
    always @(posedge clk_write or posedge reset) begin
        if (reset) begin
            count_current <= 0;
        end else begin
            count_current <= count_next;
        end
    end
    
    always @(*) begin
        count_next = count_current;
        
        if (write_en && !full_reg && (!read_en || empty_reg))
            count_next = count_inc;
        else if (read_en && !empty_reg && (!write_en || full_reg))
            count_next = count_dec;
    end
endmodule