//SystemVerilog
module lfsr #(parameter [15:0] POLY = 16'h8016) (
    input wire clock, reset,
    output wire [15:0] lfsr_out,
    output wire sequence_bit
);
    reg [15:0] lfsr_reg;
    wire feedback;
    
    // Buffered registers for high fanout signals
    reg [15:0] lfsr_reg_buf1;
    reg [15:0] lfsr_reg_buf2;
    
    // Feedback calculation using first buffer to reduce load on primary register
    assign feedback = ^(lfsr_reg_buf1 & POLY);
    
    // Main LFSR shift register logic
    always @(posedge clock) begin
        if (reset)
            lfsr_reg <= 16'h0001;
        else
            lfsr_reg <= {lfsr_reg[14:0], feedback};
    end
    
    // Buffer stages to distribute fanout load
    always @(posedge clock) begin
        if (reset) begin
            lfsr_reg_buf1 <= 16'h0001;
            lfsr_reg_buf2 <= 16'h0001;
        end
        else begin
            lfsr_reg_buf1 <= lfsr_reg;
            lfsr_reg_buf2 <= lfsr_reg;
        end
    end
    
    // Output assignments from different buffers to balance load
    assign lfsr_out = lfsr_reg_buf1;
    assign sequence_bit = lfsr_reg_buf2[15];
endmodule