//SystemVerilog
module masked_d_latch_top (
    input wire [7:0] d_in,
    input wire [7:0] mask,
    input wire enable,
    output wire [7:0] q_out
);

    wire [7:0] masked_data;
    data_masker u_data_masker (
        .d_in(d_in),
        .mask(mask),
        .masked_data(masked_data)
    );

    wire [7:0] latched_data;
    latch_controller u_latch_controller (
        .masked_data(masked_data),
        .mask(mask),
        .enable(enable),
        .q_out(q_out),
        .latched_data(latched_data)
    );

endmodule

module data_masker (
    input wire [7:0] d_in,
    input wire [7:0] mask,
    output wire [7:0] masked_data
);
    // 使用桶形移位器结构实现位与操作
    wire [7:0] barrel_shift [7:0];
    
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : barrel_shift_gen
            assign barrel_shift[i] = mask[i] ? (d_in & (8'b1 << i)) : 8'b0;
        end
    endgenerate
    
    assign masked_data = barrel_shift[0] | barrel_shift[1] | barrel_shift[2] | barrel_shift[3] |
                         barrel_shift[4] | barrel_shift[5] | barrel_shift[6] | barrel_shift[7];
endmodule

module latch_controller (
    input wire [7:0] masked_data,
    input wire [7:0] mask,
    input wire enable,
    output reg [7:0] q_out,
    output wire [7:0] latched_data
);
    // 使用桶形移位器结构实现位与操作
    wire [7:0] inv_barrel_shift [7:0];
    
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : inv_barrel_shift_gen
            assign inv_barrel_shift[i] = ~mask[i] ? (q_out & (8'b1 << i)) : 8'b0;
        end
    endgenerate
    
    assign latched_data = inv_barrel_shift[0] | inv_barrel_shift[1] | inv_barrel_shift[2] | inv_barrel_shift[3] |
                          inv_barrel_shift[4] | inv_barrel_shift[5] | inv_barrel_shift[6] | inv_barrel_shift[7];
    
    always @* begin
        if (enable) begin
            q_out = masked_data | latched_data;
        end
    end
endmodule