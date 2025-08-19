//SystemVerilog
// Top level module
module mask_decoder (
    input wire clk,
    input wire rst_n,
    input wire [7:0] addr,
    input wire [7:0] mask,
    output reg [3:0] sel
);

    wire [7:0] masked_addr;
    wire [3:0] decode_result;

    // Address masking submodule
    addr_masker u_addr_masker (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .mask(mask),
        .masked_addr(masked_addr)
    );

    // Decode logic submodule
    addr_decoder u_addr_decoder (
        .clk(clk),
        .rst_n(rst_n),
        .masked_addr(masked_addr),
        .decode_result(decode_result)
    );

    // Output register submodule
    output_reg u_output_reg (
        .clk(clk),
        .rst_n(rst_n),
        .decode_result(decode_result),
        .sel(sel)
    );

endmodule

// Address masking submodule
module addr_masker (
    input wire clk,
    input wire rst_n,
    input wire [7:0] addr,
    input wire [7:0] mask,
    output reg [7:0] masked_addr
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_addr <= 8'h0;
        end else begin
            masked_addr <= addr & mask;
        end
    end

endmodule

// Address decoder submodule
module addr_decoder (
    input wire clk,
    input wire rst_n,
    input wire [7:0] masked_addr,
    output reg [3:0] decode_result
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_result <= 4'b0000;
        end else begin
            case (masked_addr)
                8'h00: decode_result <= 4'b0001;
                8'h10: decode_result <= 4'b0010;
                8'h20: decode_result <= 4'b0100;
                8'h30: decode_result <= 4'b1000;
                default: decode_result <= 4'b0000;
            endcase
        end
    end

endmodule

// Output register submodule
module output_reg (
    input wire clk,
    input wire rst_n,
    input wire [3:0] decode_result,
    output reg [3:0] sel
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel <= 4'b0000;
        end else begin
            sel <= decode_result;
        end
    end

endmodule