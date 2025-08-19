//SystemVerilog
module config_reg_decoder #(
    parameter REGISTERED_OUTPUT = 1
)(
    input clk,
    input valid,
    output ready,
    input [1:0] addr,
    output [3:0] dec_out
);

    wire [3:0] dec_comb;
    reg ready_reg;
    reg [3:0] addr_reg;
    reg valid_reg;
    
    // 输入寄存器
    always @(posedge clk) begin
        addr_reg <= addr;
        valid_reg <= valid;
    end

    // 解码逻辑子模块
    decoder_logic u_decoder_logic (
        .addr(addr_reg),
        .dec_comb(dec_comb)
    );

    // 寄存器子模块
    register_unit #(
        .REGISTERED_OUTPUT(REGISTERED_OUTPUT)
    ) u_register_unit (
        .clk(clk),
        .dec_comb(dec_comb),
        .dec_out(dec_out)
    );

    // Valid-Ready握手控制
    always @(posedge clk) begin
        if (valid_reg) begin
            ready_reg <= 1'b1;
        end else begin
            ready_reg <= 1'b0;
        end
    end

    assign ready = ready_reg;

endmodule

module decoder_logic (
    input [1:0] addr,
    output [3:0] dec_comb
);
    assign dec_comb = (4'b0001 << addr);
endmodule

module register_unit #(
    parameter REGISTERED_OUTPUT = 1
)(
    input clk,
    input [3:0] dec_comb,
    output [3:0] dec_out
);
    reg [3:0] dec_reg;
    
    always @(posedge clk)
        dec_reg <= dec_comb;
        
    assign dec_out = REGISTERED_OUTPUT ? dec_reg : dec_comb;
endmodule