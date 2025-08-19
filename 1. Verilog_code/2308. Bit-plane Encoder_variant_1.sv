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
    // Registered input signals
    reg enable_reg;
    reg data_valid_reg;
    reg [WIDTH-1:0] data_in_reg;
    
    // Buffer storage
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] ptr;
    
    // Buffer registers for high fanout signals
    reg [$clog2(DEPTH)-1:0] ptr_buf1, ptr_buf2, ptr_buf3;
    reg ptr_zero_flag;      // Flag to detect ptr == 0 condition
    reg ptr_max_flag;       // Flag to detect ptr == DEPTH-1 condition
    
    // Register input signals (forward register retiming)
    always @(posedge clk) begin
        if (reset) begin
            enable_reg <= 0;
            data_valid_reg <= 0;
            data_in_reg <= 0;
        end else begin
            enable_reg <= enable;
            data_valid_reg <= data_valid;
            data_in_reg <= data_in;
        end
    end
    
    // Generate buffered copies of ptr for different consumers
    always @(posedge clk) begin
        if (reset) begin
            ptr_buf1 <= 0;
            ptr_buf2 <= 0;
            ptr_buf3 <= 0;
            ptr_zero_flag <= 1;
            ptr_max_flag <= 0;
        end else begin
            ptr_buf1 <= ptr;   // For buffer write operations
            ptr_buf2 <= ptr;   // For bit output operations
            ptr_buf3 <= ptr;   // For ptr comparison operations
            ptr_zero_flag <= (ptr == 0);
            ptr_max_flag <= (ptr == DEPTH-1);
        end
    end
    
    // Main processing logic
    always @(posedge clk) begin
        if (reset) begin
            ptr <= 0;
            current_plane <= 0;
            bit_valid <= 0;
        end else if (enable_reg) begin
            if (data_valid_reg) begin
                buffer[ptr_buf1] <= data_in_reg;
                ptr <= ptr_max_flag ? 0 : ptr + 1;
            end else if (ptr_zero_flag) begin
                // Output bit-plane bits
                bit_out <= buffer[ptr_buf2][current_plane];
                bit_valid <= 1;
                
                // Move to next sample or plane
                if (ptr_max_flag) begin
                    ptr <= 0;
                    current_plane <= (current_plane == WIDTH-1) ? 0 : current_plane + 1;
                end else begin
                    ptr <= ptr + 1;
                end
            end
        end else begin
            bit_valid <= 0;
        end
    end
endmodule