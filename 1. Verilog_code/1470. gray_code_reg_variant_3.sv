//SystemVerilog
module gray_code_reg(
    input clk, reset,
    input [7:0] bin_in,
    input load, convert,
    output reg [7:0] gray_out
);
    reg [7:0] binary;
    reg [7:0] binary_pipe;
    reg [3:0] upper_half_shifted;
    reg convert_d;
    
    // First stage: Register binary input
    always @(posedge clk) begin
        if (reset)
            binary <= 8'h00;
        else if (load)
            binary <= bin_in;
    end
    
    // Second stage: Capture binary value for pipeline
    always @(posedge clk) begin
        if (reset)
            binary_pipe <= 8'h00;
        else
            binary_pipe <= binary;
    end
    
    // Second stage: Shift operation for upper half
    always @(posedge clk) begin
        if (reset)
            upper_half_shifted <= 4'h0;
        else
            upper_half_shifted <= binary[7:4] >> 1;
    end
    
    // Second stage: Convert flag delay
    always @(posedge clk) begin
        if (reset)
            convert_d <= 1'b0;
        else
            convert_d <= convert;
    end
    
    // Third stage: Generate lower 4 bits of gray code
    always @(posedge clk) begin
        if (reset)
            gray_out[3:0] <= 4'h0;
        else if (convert_d)
            gray_out[3:0] <= binary_pipe[3:0] ^ {binary_pipe[3:1], 1'b0};
    end
    
    // Third stage: Generate upper 4 bits of gray code
    always @(posedge clk) begin
        if (reset)
            gray_out[7:4] <= 4'h0;
        else if (convert_d)
            gray_out[7:4] <= binary_pipe[7:4] ^ {1'b0, upper_half_shifted[3:1]};
    end
    
endmodule