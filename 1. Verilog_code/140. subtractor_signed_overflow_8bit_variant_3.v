module subtractor_signed_overflow_8bit (
    input  wire        clk,
    input  wire        rst_n,
    input  signed [7:0] a, 
    input  signed [7:0] b, 
    output reg  signed [7:0] diff, 
    output reg         overflow
);

    // Internal signals
    reg signed [7:0] a_reg;
    reg signed [7:0] b_reg;
    wire signed [7:0] diff_next;
    wire overflow_next;
    wire [7:0] b_comp;
    
    // Buffer registers for high fanout signals
    reg signed [7:0] a_buf;
    reg signed [7:0] diff_next_buf;
    reg [7:0] b0_buf;
    reg signed [7:0] signed_buf;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            a_buf <= 8'b0;
            signed_buf <= 8'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            a_buf <= a_reg;
            signed_buf <= a_reg;
        end
    end
    
    // Stage 2: Subtraction computation using two's complement
    assign b_comp = ~b_reg + 1'b1;
    assign diff_next = a_buf + b_comp;
    
    // Buffer register for diff_next
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_next_buf <= 8'b0;
            b0_buf <= 8'b0;
        end else begin
            diff_next_buf <= diff_next;
            b0_buf <= b_comp;
        end
    end
    
    // Stage 3: Optimized overflow detection
    assign overflow_next = (signed_buf[7] ^ b_reg[7]) & (signed_buf[7] ^ diff_next_buf[7]);
    
    // Stage 4: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= 8'b0;
            overflow <= 1'b0;
        end else begin
            diff <= diff_next_buf;
            overflow <= overflow_next;
        end
    end

endmodule