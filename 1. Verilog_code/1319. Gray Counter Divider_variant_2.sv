//SystemVerilog
module gray_counter_div (
    input wire clk,
    input wire rst,
    output wire divided_clk
);
    reg [3:0] gray_count;
    reg [3:0] next_gray;
    
    // Pipeline registers for breaking long combinational paths
    reg gray_count0_reg;
    reg gray_count01_and_reg;
    reg [2:1] gray_count_xor_reg;
    
    // Stage 1: Calculate intermediate values
    always @(posedge clk) begin
        if (rst) begin
            gray_count0_reg <= 1'b0;
            gray_count01_and_reg <= 1'b0;
        end else begin
            gray_count0_reg <= ~gray_count[0];
            gray_count01_and_reg <= gray_count[1] & gray_count[0];
        end
    end
    
    // Stage 2: Calculate XOR operations for bits 1 and 2
    always @(posedge clk) begin
        if (rst) begin
            gray_count_xor_reg[1] <= 1'b0;
            gray_count_xor_reg[2] <= 1'b0;
        end else begin
            gray_count_xor_reg[1] <= gray_count[1] ^ gray_count[0];
            gray_count_xor_reg[2] <= gray_count[2] ^ gray_count01_and_reg;
        end
    end
    
    // Calculate final next gray code values
    always @(*) begin
        next_gray[0] = ~gray_count[0]; // Direct calculation for bit 0
        next_gray[1] = gray_count_xor_reg[1]; // Use pipelined value for bit 1
        next_gray[2] = gray_count_xor_reg[2]; // Use pipelined value for bit 2
        next_gray[3] = gray_count[3] ^ (gray_count[2] & gray_count01_and_reg); // Optimized bit 3 calculation
    end
    
    // Sequential logic with active-high synchronous reset
    always @(posedge clk) begin
        if (rst)
            gray_count <= 4'b0000;
        else
            gray_count <= next_gray;
    end
    
    // Output clock division
    assign divided_clk = gray_count[3];
endmodule