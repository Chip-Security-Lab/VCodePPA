module bwt_encoder #(parameter WIDTH = 8, LENGTH = 4)(
    input                    clk,
    input                    reset,
    input                    enable,
    input  [WIDTH-1:0]       data_in,
    input                    in_valid,
    output reg [WIDTH-1:0]   data_out,
    output reg               out_valid,
    output reg [$clog2(LENGTH)-1:0] index
);
    reg [WIDTH-1:0] buffer [0:LENGTH-1];
    reg [$clog2(LENGTH)-1:0] buf_ptr;
    
    always @(posedge clk) begin
        if (reset) begin
            buf_ptr <= 0;
            out_valid <= 0;
        end else if (enable && in_valid) begin
            // Fill buffer
            buffer[buf_ptr] <= data_in;
            if (buf_ptr == LENGTH-1) begin
                // Buffer full, perform BWT (simplified)
                // Just output last column for now
                data_out <= buffer[0];
                index <= 0; // Original string position
                out_valid <= 1;
            end else begin
                buf_ptr <= buf_ptr + 1;
                out_valid <= 0;
            end
        end else begin
            out_valid <= 0;
        end
    end
endmodule