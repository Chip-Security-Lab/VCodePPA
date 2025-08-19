//SystemVerilog
// Top-level module
module decoder_pipelined (
    input clk, 
    input en,
    input [5:0] addr,
    output [15:0] sel_reg
);
    wire [15:0] sel_comb;
    
    // Instantiate address decoder
    addr_decoder decoder_inst (
        .addr(addr),
        .en(en),
        .decoded_out(sel_comb)
    );
    
    // Instantiate register stage
    reg_stage reg_inst (
        .clk(clk),
        .data_in(sel_comb),
        .data_out(sel_reg)
    );
endmodule

// Address decoder submodule
module addr_decoder (
    input [5:0] addr,
    input en,
    output [15:0] decoded_out
);
    reg [15:0] decoded_out_reg;
    
    always @(*) begin
        if (en) begin
            decoded_out_reg = (1 << addr);
        end else begin
            decoded_out_reg = 16'b0;
        end
    end
    
    assign decoded_out = decoded_out_reg;
endmodule

// Register stage submodule
module reg_stage (
    input clk,
    input [15:0] data_in,
    output reg [15:0] data_out
);
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule