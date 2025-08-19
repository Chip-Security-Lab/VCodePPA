//SystemVerilog
module byte_reverser #(
    parameter BYTES = 4  // Default 32-bit word
)(
    input wire clk,
    input wire rst_n,
    input wire reverse_en,
    input wire [BYTES*8-1:0] data_in,
    output reg [BYTES*8-1:0] data_out
);
    reg [BYTES*8-1:0] data_in_reg;
    reg reverse_en_reg;
    integer j;

    // Input registers moved back to pipeline the data before combinational logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= {(BYTES*8){1'b0}};
            reverse_en_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            reverse_en_reg <= reverse_en;
        end
    end

    // Combination logic for byte reversal and output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {(BYTES*8){1'b0}};
        end else if (reverse_en_reg) begin
            for (j = 0; j < BYTES; j = j + 1) begin
                data_out[j*8 +: 8] <= data_in_reg[(BYTES-1-j)*8 +: 8];
            end
        end else begin
            data_out <= data_in_reg;
        end
    end
endmodule