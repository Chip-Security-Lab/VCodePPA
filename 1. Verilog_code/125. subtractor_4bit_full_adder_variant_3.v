module subtractor_4bit_lut (
    input clk,
    input rst_n,
    input valid_in,
    output ready_out,
    input [3:0] a,
    input [3:0] b,
    output valid_out,
    input ready_in,
    output [3:0] diff,
    output borrow
);
    reg [3:0] a_reg;
    reg [3:0] b_reg;
    reg [3:0] diff_reg;
    reg borrow_reg;
    reg valid_out_reg;
    reg ready_out_reg;
    
    wire [3:0] b_complement;
    wire [3:0] lut_out;
    wire [3:0] carry;
    
    reg [15:0] sub_lut [0:15];
    initial begin
        sub_lut[0] = 16'h0000; sub_lut[1] = 16'h0001; sub_lut[2] = 16'h0002; sub_lut[3] = 16'h0003;
        sub_lut[4] = 16'h0004; sub_lut[5] = 16'h0005; sub_lut[6] = 16'h0006; sub_lut[7] = 16'h0007;
        sub_lut[8] = 16'h0008; sub_lut[9] = 16'h0009; sub_lut[10] = 16'h000A; sub_lut[11] = 16'h000B;
        sub_lut[12] = 16'h000C; sub_lut[13] = 16'h000D; sub_lut[14] = 16'h000E; sub_lut[15] = 16'h000F;
    end
    
    assign b_complement = ~b_reg;
    assign lut_out = sub_lut[{a_reg, b_complement}];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            diff_reg <= 4'b0;
            borrow_reg <= 1'b0;
            valid_out_reg <= 1'b0;
            ready_out_reg <= 1'b1;
        end else begin
            if (valid_in && ready_out_reg) begin
                a_reg <= a;
                b_reg <= b;
                diff_reg <= lut_out[3:0];
                borrow_reg <= lut_out[4];
                valid_out_reg <= 1'b1;
            end
            
            if (valid_out_reg && ready_in) begin
                valid_out_reg <= 1'b0;
            end
            
            ready_out_reg <= !valid_out_reg || (valid_out_reg && ready_in);
        end
    end
    
    assign diff = diff_reg;
    assign borrow = borrow_reg;
    assign valid_out = valid_out_reg;
    assign ready_out = ready_out_reg;
endmodule