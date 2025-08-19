//SystemVerilog
module nibble_swap_valid_ready (
    input              clk,
    input              rst_n,
    input      [15:0]  data_in,
    input              swap_en,
    input              data_valid,
    output reg         data_ready,
    output reg [15:0]  data_out,
    output reg         data_out_valid,
    input              data_out_ready
);
    reg [15:0] data_in_reg;
    reg        swap_en_reg;
    reg        data_valid_reg;
    reg        processing;
    wire [15:0] swapped_data;
    wire signed [15:0] mul_a;
    wire signed [15:0] mul_b;
    wire signed [31:0] mul_result;

    // Swap nibbles: [D3|D2|D1|D0] -> [D0|D1|D2|D3]
    assign swapped_data = {data_in_reg[3:0], data_in_reg[7:4], data_in_reg[11:8], data_in_reg[15:12]};

    // Example operands for multiplication (replace as needed)
    assign mul_a = swap_en_reg ? swapped_data : data_in_reg;
    assign mul_b = 16'sh00F0; // Example constant operand

    baugh_wooley_multiplier_16x16 u_baugh_wooley_multiplier (
        .clk(clk),
        .rst_n(rst_n),
        .multiplicand(mul_a),
        .multiplier(mul_b),
        .product(mul_result)
    );

    // Valid-Ready handshake for input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg     <= 16'd0;
            swap_en_reg     <= 1'b0;
            data_valid_reg  <= 1'b0;
            processing      <= 1'b0;
            data_ready      <= 1'b1;
        end else begin
            if (data_ready && data_valid && !processing) begin
                data_in_reg    <= data_in;
                swap_en_reg    <= swap_en;
                data_valid_reg <= 1'b1;
                processing     <= 1'b1;
                data_ready     <= 1'b0;
            end else if (data_out_valid && data_out_ready) begin
                data_valid_reg <= 1'b0;
                processing     <= 1'b0;
                data_ready     <= 1'b1;
            end
        end
    end

    // Output valid/ready logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out       <= 16'd0;
            data_out_valid <= 1'b0;
        end else begin
            if (processing && data_valid_reg && !data_out_valid) begin
                if (swap_en_reg)
                    data_out <= swapped_data;
                else
                    data_out <= data_in_reg;
                // If you want to output multiplication result, assign accordingly
                // data_out <= mul_result[15:0];
                data_out_valid <= 1'b1;
            end else if (data_out_valid && data_out_ready) begin
                data_out_valid <= 1'b0;
            end
        end
    end

endmodule

module baugh_wooley_multiplier_16x16 (
    input              clk,
    input              rst_n,
    input  signed [15:0] multiplicand,
    input  signed [15:0] multiplier,
    output reg signed [31:0] product
);
    reg [31:0] partial_products [0:15];
    reg [31:0] sum_partial_products;
    integer i;

    always @(*) begin
        for (i = 0; i < 16; i = i + 1) begin
            if (i == 15) begin
                partial_products[i] = { {16{multiplicand[15]}}, multiplicand } & {32{multiplier[i]}};
                partial_products[i][31] = ~partial_products[i][31];
            end else begin
                partial_products[i] = { {16{1'b0}}, multiplicand } & {32{multiplier[i]}};
            end
        end
    end

    always @(*) begin
        sum_partial_products = 
            (partial_products[0]  << 0 ) |
            (partial_products[1]  << 1 ) |
            (partial_products[2]  << 2 ) |
            (partial_products[3]  << 3 ) |
            (partial_products[4]  << 4 ) |
            (partial_products[5]  << 5 ) |
            (partial_products[6]  << 6 ) |
            (partial_products[7]  << 7 ) |
            (partial_products[8]  << 8 ) |
            (partial_products[9]  << 9 ) |
            (partial_products[10] << 10) |
            (partial_products[11] << 11) |
            (partial_products[12] << 12) |
            (partial_products[13] << 13) |
            (partial_products[14] << 14) |
            (partial_products[15] << 15);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 32'd0;
        end else begin
            product <= sum_partial_products + 
                ( { {16{multiplier[15]}}, 16'b0 } ) + 
                ( { {16{multiplicand[15]}}, 16'b0 } );
        end
    end

endmodule