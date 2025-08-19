module bit_sliced_rng (
    input wire clk_i,
    input wire rst_n_i,
    output wire [31:0] rnd_o
);
    // 修改不支持的数组语法
    reg [7:0] slice_reg0;
    reg [7:0] slice_reg1;
    reg [7:0] slice_reg2;
    reg [7:0] slice_reg3;
    wire [3:0] feedbacks;
    
    // Different feedback polynomials for each slice
    assign feedbacks[0] = slice_reg0[7] ^ slice_reg0[5] ^ slice_reg0[4] ^ slice_reg0[3];
    assign feedbacks[1] = slice_reg1[7] ^ slice_reg1[6] ^ slice_reg1[1] ^ slice_reg1[0];
    assign feedbacks[2] = slice_reg2[7] ^ slice_reg2[6] ^ slice_reg2[5] ^ slice_reg2[0];
    assign feedbacks[3] = slice_reg3[7] ^ slice_reg3[3] ^ slice_reg3[2] ^ slice_reg3[1];
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            slice_reg0 <= 8'h1;
            slice_reg1 <= 8'h2;
            slice_reg2 <= 8'h4;
            slice_reg3 <= 8'h8;
        end else begin
            slice_reg0 <= {slice_reg0[6:0], feedbacks[0]};
            slice_reg1 <= {slice_reg1[6:0], feedbacks[1]};
            slice_reg2 <= {slice_reg2[6:0], feedbacks[2]};
            slice_reg3 <= {slice_reg3[6:0], feedbacks[3]};
        end
    end
    
    assign rnd_o = {slice_reg3, slice_reg2, slice_reg1, slice_reg0};
endmodule