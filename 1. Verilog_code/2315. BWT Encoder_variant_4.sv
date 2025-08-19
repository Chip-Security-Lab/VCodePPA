//SystemVerilog
module bwt_encoder #(parameter WIDTH = 8, LENGTH = 4)(
    input                           clk,
    input                           reset,
    input                           enable,
    input      [WIDTH-1:0]          data_in,
    input                           in_valid,
    output reg [WIDTH-1:0]          data_out,
    output reg                      out_valid,
    output reg [$clog2(LENGTH)-1:0] index
);
    localparam PTR_WIDTH = $clog2(LENGTH);
    
    reg [WIDTH-1:0] buffer [0:LENGTH-1];
    reg [PTR_WIDTH-1:0] buf_ptr;
    reg buffer_full;
    
    // Reset logic
    always @(posedge clk) begin
        if (reset) begin
            buf_ptr <= {PTR_WIDTH{1'b0}};
            buffer_full <= 1'b0;
            out_valid <= 1'b0;
        end
    end
    
    // Buffer management
    always @(posedge clk) begin
        if (!reset && enable && in_valid) begin
            // Store incoming data
            buffer[buf_ptr] <= data_in;
            
            // Update buffer pointer and full status
            if (buf_ptr == LENGTH-1) begin
                buf_ptr <= {PTR_WIDTH{1'b0}};
                buffer_full <= 1'b1;
            end 
            else begin
                buf_ptr <= buf_ptr + 1'b1;
            end
        end
    end
    
    // Output generation
    always @(posedge clk) begin
        // Default state
        if (!reset) begin
            out_valid <= 1'b0;
            
            if (enable && in_valid && (buffer_full || buf_ptr == LENGTH-1)) begin
                data_out <= buffer[0];
                index <= {PTR_WIDTH{1'b0}}; // Original string position
                out_valid <= 1'b1;
                buffer_full <= 1'b0;
            end
        end
    end
endmodule