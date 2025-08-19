//SystemVerilog
module bitwise_mix (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_a,
    input wire [7:0] data_b,
    output reg [7:0] xor_out,
    output reg [7:0] nand_out
);

    // Pipeline stage 1: Input registers
    reg [7:0] data_a_reg;
    reg [7:0] data_b_reg;

    // Pipeline stage 2: Computation
    wire [7:0] xor_result;
    wire [7:0] nand_result;

    // Pipeline stage 3: Output registers

    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a_reg <= 8'b0;
            data_b_reg <= 8'b0;
        end else begin
            data_a_reg <= data_a;
            data_b_reg <= data_b;
        end
    end

    // Stage 2: Bitwise operations
    assign xor_result = data_a_reg ^ data_b_reg;
    assign nand_result = ~(data_a_reg & data_b_reg);

    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_out <= 8'b0;
            nand_out <= 8'b0;
        end else begin
            xor_out <= xor_result;
            nand_out <= nand_result;
        end
    end

endmodule