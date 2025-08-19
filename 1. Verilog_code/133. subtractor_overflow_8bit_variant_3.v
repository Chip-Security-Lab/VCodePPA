module subtractor_overflow_8bit (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [7:0] diff,
    output reg overflow
);

    // Pipeline stage 1: Input registers
    reg [7:0] a_reg;
    reg [7:0] b_reg;
    
    // Pipeline stage 2: Subtraction result
    reg [7:0] diff_reg;
    reg overflow_reg;
    
    // Input stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // Subtraction logic
    wire [7:0] diff_wire;
    wire overflow_wire;
    
    assign diff_wire = a_reg - b_reg;
    
    // Overflow detection logic
    assign overflow_wire = (a_reg[7] & ~b_reg[7] & ~diff_wire[7]) | 
                          (~a_reg[7] & b_reg[7] & diff_wire[7]);
    
    // Pipeline stage 2: Register subtraction result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_reg <= 8'b0;
            overflow_reg <= 1'b0;
        end else begin
            diff_reg <= diff_wire;
            overflow_reg <= overflow_wire;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= 8'b0;
            overflow <= 1'b0;
        end else begin
            diff <= diff_reg;
            overflow <= overflow_reg;
        end
    end

endmodule