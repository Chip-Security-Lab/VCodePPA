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

    // Pipeline stage 1: Address comparison
    reg [WIDTH-1:0] addr_reg;
    wire [2**WIDTH-1:0] comp_out;
    
    // Pipeline stage 2: Enable control
    reg [2**WIDTH-1:0] comp_out_reg;
    reg enable_reg;
    
    // Address comparison logic
    addr_compare #(
        .WIDTH(WIDTH)
    ) addr_comp (
        .addr(addr_reg),
        .comp_out(comp_out)
    );
    
    // Pipeline stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= {WIDTH{1'b0}};
            enable_reg <= 1'b0;
        end else begin
            addr_reg <= addr;
            enable_reg <= enable;
        end
    end
    
    // Pipeline stage 2: Register comparison results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comp_out_reg <= {(2**WIDTH){1'b0}};
        end else begin
            comp_out_reg <= comp_out;
        end
    end
    
    // Pipeline stage 3: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dec_out <= {(2**WIDTH){1'b0}};
        end else begin
            dec_out <= enable_reg ? comp_out_reg : {(2**WIDTH){1'b0}};
        end
    end

endmodule

module addr_compare #(
    parameter WIDTH = 3
)(
    input [WIDTH-1:0] addr,
    output [2**WIDTH-1:0] comp_out
);
    genvar i;
    generate
        for (i = 0; i < 2**WIDTH; i = i + 1) begin: gen_loop
            assign comp_out[i] = (addr == i) ? 1'b1 : 1'b0;
        end
    endgenerate
endmodule