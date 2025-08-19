//SystemVerilog
module booth_multiplier (
    input wire clk,
    input wire rst_n,
    input wire [3:0] multiplicand,
    input wire [3:0] multiplier,
    output reg [7:0] product
);

    // Booth algorithm states
    reg [3:0] A_reg;
    reg [3:0] Q_reg;
    reg Q_1;
    reg [1:0] count;
    
    // Pipeline registers
    reg [3:0] multiplicand_reg;
    reg [3:0] multiplier_reg;
    reg [7:0] product_reg;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplicand_reg <= 4'b0;
            multiplier_reg <= 4'b0;
        end else begin
            multiplicand_reg <= multiplicand;
            multiplier_reg <= multiplier;
        end
    end
    
    // Stage 2: Booth multiplication
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= 4'b0;
            Q_reg <= 4'b0;
            Q_1 <= 1'b0;
            count <= 2'b0;
            product_reg <= 8'b0;
        end else begin
            if (count == 2'b0) begin
                A_reg <= 4'b0;
                Q_reg <= multiplier_reg;
                Q_1 <= 1'b0;
                count <= 2'b11;
            end else begin
                case ({Q_reg[0], Q_1})
                    2'b01: A_reg <= A_reg + multiplicand_reg;
                    2'b10: A_reg <= A_reg - multiplicand_reg;
                    default: A_reg <= A_reg;
                endcase
                
                {A_reg, Q_reg, Q_1} <= {A_reg[3], A_reg, Q_reg};
                count <= count - 1;
                
                if (count == 2'b01) begin
                    product_reg <= {A_reg, Q_reg};
                end
            end
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 8'b0;
        end else begin
            product <= product_reg;
        end
    end

endmodule