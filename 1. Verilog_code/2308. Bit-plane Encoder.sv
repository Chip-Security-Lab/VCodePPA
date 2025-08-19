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
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] ptr;
    
    always @(posedge clk) begin
        if (reset) begin
            ptr <= 0;
            current_plane <= 0;
            bit_valid <= 0;
        end else if (enable) begin
            if (data_valid) begin
                buffer[ptr] <= data_in;
                ptr <= (ptr == DEPTH-1) ? 0 : ptr + 1;
            end else if (ptr == 0) begin
                // Output bit-plane bits
                bit_out <= buffer[ptr][current_plane];
                bit_valid <= 1;
                
                // Move to next sample or plane
                if (ptr == DEPTH-1) begin
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