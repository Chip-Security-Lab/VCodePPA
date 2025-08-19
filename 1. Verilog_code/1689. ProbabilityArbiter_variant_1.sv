//SystemVerilog
module LFSR #(parameter SEED=8'hA5) (
    input clk,
    input rst,
    output reg [7:0] lfsr_out
);
    always @(posedge clk) begin
        if(rst) begin
            lfsr_out <= SEED;
        end else begin
            lfsr_out <= {lfsr_out[6:0], lfsr_out[7] ^ lfsr_out[5] ^ lfsr_out[4] ^ lfsr_out[3]};
        end
    end
endmodule

module RequestMask (
    input [3:0] req,
    output [3:0] req_mask
);
    assign req_mask = req & {4{|req}};
endmodule

module GrantSelector (
    input [1:0] lfsr_bits,
    input [3:0] req_mask,
    output reg [3:0] grant
);
    always @(*) begin
        case(lfsr_bits)
            2'b00: grant = req_mask & 4'b0001;
            2'b01: grant = req_mask & 4'b0010;
            2'b10: grant = req_mask & 4'b0100;
            2'b11: grant = req_mask & 4'b1000;
        endcase
    end
endmodule

module ProbabilityArbiter #(parameter SEED=8'hA5) (
    input clk,
    input rst,
    input [3:0] req,
    output reg [3:0] grant,
    output reg ack
);
    wire [7:0] lfsr_out;
    wire [3:0] req_mask;
    reg req_reg;
    
    LFSR #(.SEED(SEED)) lfsr_inst (
        .clk(clk),
        .rst(rst),
        .lfsr_out(lfsr_out)
    );
    
    RequestMask req_mask_inst (
        .req(req),
        .req_mask(req_mask)
    );
    
    GrantSelector grant_selector_inst (
        .lfsr_bits(lfsr_out[1:0]),
        .req_mask(req_mask),
        .grant(grant)
    );

    always @(posedge clk) begin
        if(rst) begin
            req_reg <= 1'b0;
            ack <= 1'b0;
        end else begin
            req_reg <= |req;
            ack <= req_reg;
        end
    end
endmodule