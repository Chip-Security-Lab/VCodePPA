//SystemVerilog
module decoder_hier #(parameter NUM_SLAVES=4) (
    input clk,
    input rst_n,
    input [7:0] addr,
    output reg [3:0] high_decode,
    output reg [3:0] low_decode
);

    // Pipeline registers
    reg [3:0] addr_high_reg;
    reg [3:0] addr_low_reg;
    reg [3:0] high_decode_reg;
    reg [3:0] low_decode_reg;

    // Address split pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_high_reg <= 4'b0;
            addr_low_reg <= 4'b0;
        end else begin
            addr_high_reg <= addr[7:4];
            addr_low_reg <= addr[3:0];
        end
    end

    // High address decoder pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            high_decode_reg <= 4'b0;
        end else begin
            high_decode_reg <= (addr_high_reg < NUM_SLAVES) ? (1 << addr_high_reg) : 4'b0;
        end
    end

    // Low address decoder pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            low_decode_reg <= 4'b0;
        end else begin
            low_decode_reg <= 1 << addr_low_reg;
        end
    end

    // Output pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            high_decode <= 4'b0;
            low_decode <= 4'b0;
        end else begin
            high_decode <= high_decode_reg;
            low_decode <= low_decode_reg;
        end
    end

endmodule