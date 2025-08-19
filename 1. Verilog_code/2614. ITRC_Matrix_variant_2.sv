//SystemVerilog
module ITRC_Matrix #(
    parameter SOURCES = 4,
    parameter TARGETS = 2
)(
    input clk,
    input rst_n,
    input [SOURCES-1:0] int_src,
    input [TARGETS*SOURCES-1:0] routing_map,
    output [TARGETS-1:0] int_out
);

    // Pipeline stage registers
    reg [SOURCES-1:0] src_reg;
    reg [TARGETS*SOURCES-1:0] map_reg;
    reg [TARGETS-1:0] out_reg;

    // Input pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            src_reg <= 0;
            map_reg <= 0;
        end else begin
            src_reg <= int_src;
            map_reg <= routing_map;
        end
    end

    genvar t;
    generate
        for (t=0; t<TARGETS; t=t+1) begin : gen_target
            // Masking stage
            wire [SOURCES-1:0] mask = map_reg[t*SOURCES +: SOURCES];
            wire [SOURCES-1:0] masked_src = src_reg & mask;
            
            // Booth multiplier pipeline registers
            reg [SOURCES:0] booth_prod_reg;
            reg [SOURCES-1:0] booth_acc_reg;
            reg [1:0] booth_state_reg;
            
            // Booth multiplier pipeline stage
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    booth_prod_reg <= 0;
                    booth_acc_reg <= 0;
                    booth_state_reg <= 0;
                end else begin
                    case (booth_state_reg)
                        0: begin
                            booth_prod_reg <= {masked_src, 1'b0};
                            booth_acc_reg <= 0;
                            booth_state_reg <= 1;
                        end
                        1: begin
                            if (booth_prod_reg[0] && !booth_prod_reg[1]) begin
                                booth_acc_reg <= booth_acc_reg + booth_prod_reg[SOURCES:1];
                            end else if (!booth_prod_reg[0] && booth_prod_reg[1]) begin
                                booth_acc_reg <= booth_acc_reg - booth_prod_reg[SOURCES:1];
                            end
                            booth_prod_reg <= booth_prod_reg >> 1;
                            booth_state_reg <= (booth_prod_reg[SOURCES:1] == 0) ? 2 : 1;
                        end
                        2: begin
                            booth_state_reg <= 0;
                        end
                    endcase
                end
            end
            
            // Output pipeline stage
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    out_reg[t] <= 0;
                end else begin
                    out_reg[t] <= |booth_acc_reg;
                end
            end
        end
    endgenerate

    assign int_out = out_reg;
endmodule