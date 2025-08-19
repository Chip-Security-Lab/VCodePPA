//SystemVerilog
module crc32_ethernet (
    input clk, rst,
    input valid_in,
    input [31:0] data_in,
    output reg ready_out,
    output reg valid_out,
    output reg [31:0] crc_out,
    input ready_in
);
    parameter POLY = 32'h04C11DB7;
    
    reg processing;
    reg [31:0] crc_next;
    reg [31:0] data_in_reg;
    reg valid_in_reg;
    
    wire [31:0] data_rev;
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_rev
            assign data_rev[i] = data_in_reg[31-i];
        end
    endgenerate
    
    wire [31:0] crc_xord;
    assign crc_xord = crc_next ^ data_rev;
    
    wire feedback_bit;
    assign feedback_bit = crc_xord[31];
    
    wire [31:0] next_val;
    generate
        for (i = 0; i < 31; i = i + 1) begin : gen_next_val
            wire use_poly;
            wire shifted_bit;
            assign use_poly = POLY[i] & feedback_bit;
            assign shifted_bit = (i > 0) ? crc_xord[i-1] : 1'b0;
            assign next_val[i] = feedback_bit ^ shifted_bit ^ use_poly;
        end
    endgenerate
    
    wire use_poly_msb;
    assign use_poly_msb = POLY[31] & feedback_bit;
    assign next_val[31] = feedback_bit ^ crc_xord[30] ^ use_poly_msb;
    
    always @(posedge clk) begin
        if (rst) begin
            crc_next <= 32'hFFFFFFFF;
            ready_out <= 1'b1;
            valid_out <= 1'b0;
            processing <= 1'b0;
            data_in_reg <= 32'h0;
            valid_in_reg <= 1'b0;
        end
        else begin
            if (valid_in && ready_out) begin
                data_in_reg <= data_in;
                valid_in_reg <= 1'b1;
                ready_out <= 1'b0;
            end
            
            if (valid_in_reg) begin
                crc_next <= next_val;
                processing <= 1'b1;
                valid_in_reg <= 1'b0;
            end
            
            if (processing) begin
                valid_out <= 1'b1;
                crc_out <= crc_next;
                processing <= 1'b0;
            end
            
            if (valid_out && ready_in) begin
                valid_out <= 1'b0;
                ready_out <= 1'b1;
            end
        end
    end
endmodule