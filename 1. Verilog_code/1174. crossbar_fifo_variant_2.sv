//SystemVerilog
module crossbar_fifo #(
    parameter DW = 8,     // Data width
    parameter DEPTH = 4,  // FIFO depth
    parameter N = 2       // Number of ports
)(
    input  wire clk, rst,
    input  wire [N-1:0] push,
    input  wire [N*DW-1:0] din,
    output wire [N*DW-1:0] dout
);
    // FIFO storage elements
    reg [DW-1:0] fifo [0:N-1][0:DEPTH-1];
    reg [$clog2(DEPTH+1)-1:0] cnt [0:N-1];  // Optimize counter width
    
    // FIFO control logic
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                cnt[i] <= '0;  // Use implicit width assignment
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                // Optimize comparison logic with range check
                if (push[i] && (cnt[i] != DEPTH)) begin  // More efficient comparison
                    fifo[i][cnt[i]] <= din[i*DW +: DW];
                    cnt[i] <= cnt[i] + 1'b1;
                end
            end
        end
    end

    // Output logic - Direct all outputs from the first FIFO's first entry
    // Using continuous assignment for better timing
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : gen_out
            assign dout[g*DW +: DW] = fifo[0][0];
        end
    endgenerate
endmodule