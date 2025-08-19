//SystemVerilog
module gray2bin_seq #(parameter DATA_W = 8) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [DATA_W-1:0] gray_code,
    output reg [DATA_W-1:0] binary_out
);

    reg [DATA_W-1:0] gray_code_reg;
    reg [DATA_W-1:0] binary_reg;
    integer i;

    // Register the input gray_code first (retiming register moved before combinational logic)
    always @(posedge clk or negedge rst_n) begin : gray_code_input_reg
        if (!rst_n) begin
            gray_code_reg <= {DATA_W{1'b0}};
        end
        else if (enable) begin
            gray_code_reg <= gray_code;
        end
    end

    // Combinational logic: Gray code to binary conversion
    always @(*) begin : gray2bin_comb_logic
        binary_reg[DATA_W-1] = gray_code_reg[DATA_W-1];
        for (i = DATA_W-2; i >= 0; i = i - 1) begin
            binary_reg[i] = binary_reg[i+1] ^ gray_code_reg[i];
        end
    end

    // Sequential logic: Register for binary_out (register moved before output)
    always @(posedge clk or negedge rst_n) begin : binary_out_reg
        if (!rst_n) begin
            binary_out <= {DATA_W{1'b0}};
        end
        else if (enable) begin
            binary_out <= binary_reg;
        end
    end

endmodule