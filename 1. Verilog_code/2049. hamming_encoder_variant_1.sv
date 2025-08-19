//SystemVerilog
module hamming_encoder (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [3:0]   data_in,
    output wire [6:0]   hamming_out
);

// Stage 1: Input register
reg [3:0] input_data_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        input_data_reg <= 4'b0;
    else
        input_data_reg <= data_in;
end

// Stage 2: Parity computation (optimized)
reg [2:0] parity_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        parity_reg <= 3'b0;
    else begin
        // Using direct assignments for clarity and efficiency
        parity_reg[0] <= ^{input_data_reg[0], input_data_reg[1], input_data_reg[3]}; // parity0
        parity_reg[1] <= ^{input_data_reg[0], input_data_reg[2], input_data_reg[3]}; // parity1
        parity_reg[2] <= ^{input_data_reg[1], input_data_reg[2], input_data_reg[3]}; // parity3
    end
end

// Stage 3: Data bits register
reg [3:0] data_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        data_reg <= 4'b0;
    else
        data_reg <= input_data_reg;
end

// Stage 4: Output register (optimized bit assignment)
reg [6:0] hamming_out_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        hamming_out_reg <= 7'b0;
    else
        hamming_out_reg <= {data_reg[3], data_reg[2], data_reg[1], parity_reg[2], data_reg[0], parity_reg[1], parity_reg[0]};
end

assign hamming_out = hamming_out_reg;

endmodule