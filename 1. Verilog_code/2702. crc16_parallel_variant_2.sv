//SystemVerilog
module crc16_parallel #(parameter INIT = 16'hFFFF) (
    input clk, load_en,
    input [15:0] data_in,
    output reg [15:0] crc_reg
);

    // 流水线寄存器
    reg [7:0] a_reg, b_reg;
    reg [3:0] a_high_reg, a_low_reg, b_high_reg, b_low_reg;
    reg [7:0] a_high_b_high_reg, a_low_b_low_reg, cross_term_reg;
    reg [15:0] a_mul_b_reg;
    reg [7:0] idx_reg;
    reg [15:0] next_crc_reg;

    function [15:0] lookup_value;
        input [7:0] idx;
        reg [7:0] a, b;
        reg [15:0] a_mul_b;
        reg [3:0] a_high, a_low, b_high, b_low;
        reg [7:0] a_high_b_high, a_low_b_low, cross_term;
        begin
            a = idx;
            b = 8'h21;
            
            a_high = a[7:4];
            a_low = a[3:0];
            b_high = b[7:4];
            b_low = b[3:0];
            
            a_high_b_high = a_high * b_high;
            a_low_b_low = a_low * b_low;
            cross_term = (a_high + a_low) * (b_high + b_low) - a_high_b_high - a_low_b_low;
            
            a_mul_b = {a_high_b_high, 8'b0} + {cross_term, 4'b0} + a_low_b_low;
            
            if (a != 0) begin
                a_mul_b = a_mul_b | (a << 12);
            end
            
            case(idx)
                8'h00: lookup_value = 16'h0000;
                8'h01: lookup_value = 16'h1021;
                8'h02: lookup_value = 16'h2042;
                8'hFD: lookup_value = 16'hB8ED;
                8'hFE: lookup_value = 16'hA9CE;
                8'hFF: lookup_value = 16'h9ACF;
                default: lookup_value = a_mul_b;
            endcase
        end
    endfunction

    // 第一级流水线
    always @(posedge clk) begin
        if (load_en) begin
            a_reg <= crc_reg[15:8] ^ data_in[15:8];
            b_reg <= 8'h21;
        end
    end

    // 第二级流水线
    always @(posedge clk) begin
        if (load_en) begin
            a_high_reg <= a_reg[7:4];
            a_low_reg <= a_reg[3:0];
            b_high_reg <= b_reg[7:4];
            b_low_reg <= b_reg[3:0];
        end
    end

    // 第三级流水线
    always @(posedge clk) begin
        if (load_en) begin
            a_high_b_high_reg <= a_high_reg * b_high_reg;
            a_low_b_low_reg <= a_low_reg * b_low_reg;
            cross_term_reg <= (a_high_reg + a_low_reg) * (b_high_reg + b_low_reg) - 
                            a_high_b_high_reg - a_low_b_low_reg;
        end
    end

    // 第四级流水线
    always @(posedge clk) begin
        if (load_en) begin
            a_mul_b_reg <= {a_high_b_high_reg, 8'b0} + 
                          {cross_term_reg, 4'b0} + 
                          a_low_b_low_reg;
            if (a_reg != 0) begin
                a_mul_b_reg <= a_mul_b_reg | (a_reg << 12);
            end
        end
    end

    // 第五级流水线
    always @(posedge clk) begin
        if (load_en) begin
            next_crc_reg <= {crc_reg[7:0], 8'h00} ^ lookup_value(a_reg);
        end
    end

    initial begin
        crc_reg = INIT;
    end

    always @(posedge clk) begin
        if (load_en) begin
            crc_reg <= next_crc_reg;
        end
    end

endmodule