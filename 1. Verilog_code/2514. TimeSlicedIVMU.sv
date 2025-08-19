module TimeSlicedIVMU (
    input clk, rst,
    input [15:0] irq_in,
    input [3:0] time_slice,
    output reg [31:0] vector_addr,
    output reg irq_out
);
    reg [31:0] vector_table [0:15];
    reg [3:0] current_slice;
    wire [15:0] slice_masked;
    integer i;
    
    initial for (i = 0; i < 16; i = i + 1)
        vector_table[i] = 32'hC000_0000 + (i << 6);
    
    assign slice_masked = irq_in & (16'h1 << time_slice);
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_slice <= 4'h0;
            irq_out <= 1'b0;
        end else begin
            current_slice <= time_slice;
            
            irq_out <= |slice_masked;
            if (|slice_masked) begin
                for (i = 15; i >= 0; i = i - 1)
                    if (slice_masked[i]) vector_addr <= vector_table[i];
            end
        end
    end
endmodule