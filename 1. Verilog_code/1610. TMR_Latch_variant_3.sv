//SystemVerilog
module TMR_Latch #(parameter DW=8) (
    input clk,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

    // Register signals
    wire [DW-1:0] reg1_out, reg2_out, reg3_out;
    wire [DW-1:0] majority_out;
    
    // Instantiate input registers
    TMR_Register #(.DW(DW)) reg1_inst (
        .clk(clk),
        .din(din),
        .dout(reg1_out)
    );
    
    TMR_Register #(.DW(DW)) reg2_inst (
        .clk(clk),
        .din(din),
        .dout(reg2_out)
    );
    
    TMR_Register #(.DW(DW)) reg3_inst (
        .clk(clk),
        .din(din),
        .dout(reg3_out)
    );
    
    // Instantiate majority voter
    Majority_Voter #(.DW(DW)) voter_inst (
        .clk(clk),
        .reg1(reg1_out),
        .reg2(reg2_out),
        .reg3(reg3_out),
        .dout(majority_out)
    );
    
    // Output register
    TMR_Register #(.DW(DW)) out_reg_inst (
        .clk(clk),
        .din(majority_out),
        .dout(dout)
    );
    
endmodule

module TMR_Register #(parameter DW=8) (
    input clk,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    always @(posedge clk) begin
        dout <= din;
    end
endmodule

module Majority_Voter #(parameter DW=8) (
    input clk,
    input [DW-1:0] reg1,
    input [DW-1:0] reg2,
    input [DW-1:0] reg3,
    output reg [DW-1:0] dout
);
    genvar i;
    generate
        for (i = 0; i < DW; i = i + 1) begin : gen_majority
            wire [2:0] vote_input = {reg1[i], reg2[i], reg3[i]};
            wire majority_bit;
            
            assign majority_bit = (vote_input[0] & vote_input[1]) | 
                                (vote_input[1] & vote_input[2]) | 
                                (vote_input[0] & vote_input[2]);
            
            always @(posedge clk) begin
                dout[i] <= majority_bit;
            end
        end
    endgenerate
endmodule