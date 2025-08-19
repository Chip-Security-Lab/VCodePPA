//SystemVerilog
module endian_swap (
    input               clk,
    input               rst_n,
    input  [31:0]       data_in,
    input               data_in_valid,
    output reg [31:0]   data_out,
    output reg          data_out_valid
);

    // Stage 1: Input register
    reg [31:0] input_reg;
    reg        valid_reg;

    // Stage 2: Swapped data register
    reg [31:0] swapped_reg;

    // Input data latching
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_reg <= 32'b0;
        end else begin
            input_reg <= data_in;
        end
    end

    // Input valid latching
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_reg <= 1'b0;
        end else begin
            valid_reg <= data_in_valid;
        end
    end

    // Byte swap combinational logic and latching
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            swapped_reg <= 32'b0;
        end else begin
            swapped_reg <= {input_reg[7:0], input_reg[15:8], input_reg[23:16], input_reg[31:24]};
        end
    end

    // Output data latching
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 32'b0;
        end else begin
            data_out <= swapped_reg;
        end
    end

    // Output valid latching
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_valid <= 1'b0;
        end else begin
            data_out_valid <= valid_reg;
        end
    end

endmodule