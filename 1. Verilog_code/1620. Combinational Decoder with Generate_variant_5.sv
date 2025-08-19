//SystemVerilog
module gen_decoder #(
    parameter WIDTH = 3
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] addr,
    input enable,
    output reg [2**WIDTH-1:0] dec_out
);

    // Pipeline stage 1: Address decoding
    wire [2**WIDTH-1:0] addr_dec_out;
    reg [2**WIDTH-1:0] addr_dec_reg;
    
    // Pipeline stage 2: Enable control
    reg [2**WIDTH-1:0] enable_reg;
    reg enable_ctrl_reg;

    // Address decoder with optimized implementation
    addr_decoder #(
        .WIDTH(WIDTH)
    ) u_addr_decoder (
        .addr(addr),
        .dec_out(addr_dec_out)
    );

    // Pipeline stage 1: Register address decode result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_dec_reg <= {(2**WIDTH){1'b0}};
        end else begin
            addr_dec_reg <= addr_dec_out;
        end
    end

    // Pipeline stage 2: Register enable and control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_reg <= {(2**WIDTH){1'b0}};
            enable_ctrl_reg <= 1'b0;
        end else begin
            enable_reg <= addr_dec_reg;
            enable_ctrl_reg <= enable;
        end
    end

    // Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dec_out <= {(2**WIDTH){1'b0}};
        end else begin
            dec_out <= enable_ctrl_reg ? enable_reg : {(2**WIDTH){1'b0}};
        end
    end

endmodule

module addr_decoder #(
    parameter WIDTH = 3
)(
    input [WIDTH-1:0] addr,
    output [2**WIDTH-1:0] dec_out
);
    // Optimized decoder implementation with reduced combinational logic
    reg [2**WIDTH-1:0] dec_out_reg;
    integer i;
    
    // First stage: Pre-compute address comparison results
    reg [2**WIDTH-1:0] addr_match;
    
    always @(*) begin
        for (i = 0; i < 2**WIDTH; i = i + 1) begin
            addr_match[i] = (addr == i);
        end
    end
    
    // Second stage: Generate decoder output
    always @(*) begin
        for (i = 0; i < 2**WIDTH; i = i + 1) begin
            dec_out_reg[i] = addr_match[i];
        end
    end
    
    assign dec_out = dec_out_reg;
endmodule