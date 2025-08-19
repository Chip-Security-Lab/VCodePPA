//SystemVerilog
module parity_gen_check(
    input wire clk, rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire parity_type, // 0:even, 1:odd
    input wire gen_check_n, // 0:check, 1:generate
    output reg parity_bit,
    output reg error
);
    localparam IDLE=2'b00, COMPUTE=2'b01, OUTPUT=2'b10, ERROR_STATE=2'b11;
    reg [1:0] state, next;
    reg [7:0] data_reg;
    reg computed_parity;
    
    // Baugh-Wooley multiplier signals
    wire [7:0] partial_products [7:0];
    wire [15:0] final_product;
    reg [15:0] product_reg;
    
    // Generate partial products
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_partial_products
            for (j = 0; j < 8; j = j + 1) begin : gen_pp
                assign partial_products[i][j] = data_reg[i] & data_reg[j];
            end
        end
    endgenerate
    
    // Baugh-Wooley reduction
    assign final_product[0] = partial_products[0][0];
    assign final_product[1] = partial_products[0][1] ^ partial_products[1][0];
    assign final_product[2] = partial_products[0][2] ^ partial_products[1][1] ^ partial_products[2][0];
    assign final_product[3] = partial_products[0][3] ^ partial_products[1][2] ^ partial_products[2][1] ^ partial_products[3][0];
    assign final_product[4] = partial_products[0][4] ^ partial_products[1][3] ^ partial_products[2][2] ^ partial_products[3][1] ^ partial_products[4][0];
    assign final_product[5] = partial_products[0][5] ^ partial_products[1][4] ^ partial_products[2][3] ^ partial_products[3][2] ^ partial_products[4][1] ^ partial_products[5][0];
    assign final_product[6] = partial_products[0][6] ^ partial_products[1][5] ^ partial_products[2][4] ^ partial_products[3][3] ^ partial_products[4][2] ^ partial_products[5][1] ^ partial_products[6][0];
    assign final_product[7] = partial_products[0][7] ^ partial_products[1][6] ^ partial_products[2][5] ^ partial_products[3][4] ^ partial_products[4][3] ^ partial_products[5][2] ^ partial_products[6][1] ^ partial_products[7][0];
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            data_reg <= 8'd0;
            parity_bit <= 1'b0;
            error <= 1'b0;
            computed_parity <= 1'b0;
            product_reg <= 16'd0;
        end else begin
            state <= next;
            
            case (state)
                IDLE: begin
                    error <= 1'b0;
                    if (data_valid)
                        data_reg <= data_in;
                end
                COMPUTE: begin
                    // Calculate parity using Baugh-Wooley product
                    product_reg <= final_product;
                    computed_parity <= ^product_reg[7:0] ^ parity_type;
                    
                    if (gen_check_n) // Generate mode
                        parity_bit <= ^product_reg[7:0] ^ parity_type;
                end
                OUTPUT: begin
                    if (!gen_check_n) // Check mode
                        error <= (computed_parity != parity_bit);
                end
                ERROR_STATE: error <= 1'b1;
            endcase
        end
    
    always @(*)
        case (state)
            IDLE: next = data_valid ? COMPUTE : IDLE;
            COMPUTE: next = OUTPUT;
            OUTPUT: next = (!gen_check_n && (computed_parity != parity_bit)) ? 
                          ERROR_STATE : IDLE;
            ERROR_STATE: next = IDLE;
            default: next = IDLE;
        endcase
endmodule