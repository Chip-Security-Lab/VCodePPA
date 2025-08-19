//SystemVerilog
module baugh_wooley_multiplier(
    input wire clk,
    input wire rst,
    input wire [7:0] a,
    input wire [7:0] b,
    input wire valid_in,
    output reg [15:0] product,
    output reg valid_out
);

    reg [7:0] a_reg, b_reg;
    reg [15:0] partial_products [7:0];
    reg [15:0] sum_stage1 [3:0];
    reg [15:0] sum_stage2 [1:0];
    reg [15:0] final_sum;
    reg [2:0] state;
    reg valid_reg;

    localparam IDLE = 0, COMPUTE = 1, FINISH = 2;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= IDLE;
            valid_out <= 0;
            valid_reg <= 0;
            product <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid_in) begin
                        a_reg <= a;
                        b_reg <= b;
                        state <= COMPUTE;
                        valid_reg <= 1;
                    end
                end

                COMPUTE: begin
                    // Generate partial products using Baugh-Wooley algorithm
                    for (int i = 0; i < 8; i = i + 1) begin
                        for (int j = 0; j < 8; j = j + 1) begin
                            if (i == 7 && j == 7) begin
                                partial_products[i][j] <= ~(a_reg[i] & b_reg[j]);
                            end else if (i == 7 || j == 7) begin
                                partial_products[i][j] <= a_reg[i] & b_reg[j];
                            end else begin
                                partial_products[i][j] <= a_reg[i] & b_reg[j];
                            end
                        end
                    end

                    // First stage of addition
                    for (int i = 0; i < 4; i = i + 1) begin
                        sum_stage1[i] <= partial_products[2*i] + (partial_products[2*i+1] << 1);
                    end

                    // Second stage of addition
                    for (int i = 0; i < 2; i = i + 1) begin
                        sum_stage2[i] <= sum_stage1[2*i] + (sum_stage1[2*i+1] << 2);
                    end

                    // Final addition
                    final_sum <= sum_stage2[0] + (sum_stage2[1] << 4);
                    state <= FINISH;
                end

                FINISH: begin
                    product <= final_sum;
                    valid_out <= valid_reg;
                    valid_reg <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule