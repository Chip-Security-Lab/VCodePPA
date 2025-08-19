//SystemVerilog
module mixed_precision_mult (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  A,
    input  wire [3:0]  B,
    output reg  [11:0] Result
);

    // Pipeline registers
    reg [7:0]  A_reg;
    reg [3:0]  B_reg;
    reg [11:0] mult_result;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= 8'b0;
            B_reg <= 4'b0;
        end else begin
            A_reg <= A;
            B_reg <= B;
        end
    end
    
    // Stage 2: Multiplication
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_result <= 12'b0;
        end else begin
            mult_result <= A_reg * B_reg;
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Result <= 12'b0;
        end else begin
            Result <= mult_result;
        end
    end

endmodule