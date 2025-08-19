//SystemVerilog
module crossbar_sync_prio #(parameter DW=8, N=4) (
    input clk, rst_n, en,
    input [(DW*N)-1:0] din,
    input [(N*2)-1:0] dest,
    output reg [(DW*N)-1:0] dout
);
    // Break out the destination indices
    wire [1:0] dest_indices[0:N-1];
    genvar i;
    generate
        for(i=0; i<N; i=i+1) begin : gen_dest
            assign dest_indices[i] = dest[(i*2+1):(i*2)];
        end
    endgenerate
    
    // Register din and dest_indices first to reduce input to register delay
    reg [(DW*N)-1:0] din_reg;
    reg [1:0] dest_indices_reg[0:N-1];
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            din_reg <= {(DW*N){1'b0}};
            dest_indices_reg[0] <= 2'b00;
            dest_indices_reg[1] <= 2'b00;
            dest_indices_reg[2] <= 2'b00;
            dest_indices_reg[3] <= 2'b00;
        end else if(en) begin
            din_reg <= din;
            dest_indices_reg[0] <= dest_indices[0];
            dest_indices_reg[1] <= dest_indices[1];
            dest_indices_reg[2] <= dest_indices[2];
            dest_indices_reg[3] <= dest_indices[3];
        end
    end
    
    // Implement index computation using Baugh-Wooley 2-bit multiplier
    wire [3:0] bw_prod [0:N-1]; // 2-bit x 2-bit = 4-bit product

    // Baugh-Wooley multiplier implementation for each destination index
    generate
        for(i=0; i<N; i=i+1) begin : gen_bw_mult
            baugh_wooley_2bit mult_inst (
                .a(dest_indices_reg[i]),
                .b(2'b10), // Multiply by DW/4 (assuming DW=8, so multiply by 2)
                .p(bw_prod[i])
            );
        end
    endgenerate
    
    // Move the crossbar logic after the registers, using Baugh-Wooley multiplier results
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dout <= {(DW*N){1'b0}};
        end else if(en) begin
            dout[DW-1:0] <= din_reg[(bw_prod[0][1:0]*DW/4) +: DW];
            dout[(2*DW)-1:DW] <= din_reg[(bw_prod[1][1:0]*DW/4) +: DW];
            dout[(3*DW)-1:(2*DW)] <= din_reg[(bw_prod[2][1:0]*DW/4) +: DW];
            dout[(4*DW)-1:(3*DW)] <= din_reg[(bw_prod[3][1:0]*DW/4) +: DW];
        end
    end
endmodule

// 2-bit Baugh-Wooley multiplier module
module baugh_wooley_2bit (
    input [1:0] a,
    input [1:0] b,
    output [3:0] p
);
    // Partial products
    wire pp_0_0, pp_0_1, pp_1_0, pp_1_1;
    
    // Standard partial products for positive bits
    assign pp_0_0 = a[0] & b[0];
    assign pp_0_1 = a[0] & b[1];
    assign pp_1_0 = a[1] & b[0];
    
    // Modified partial product for sign bits in Baugh-Wooley
    assign pp_1_1 = ~(a[1] & b[1]); // Negate the MSB product
    
    // Sum terms using Baugh-Wooley algorithm
    wire carry_1, carry_2, carry_3;
    wire sum_1, sum_2;
    
    // First sum term (p[0] is just pp_0_0)
    assign p[0] = pp_0_0;
    
    // Second sum term
    assign {carry_1, sum_1} = pp_0_1 + pp_1_0;
    assign p[1] = sum_1;
    
    // Third sum term (including carry from previous stage)
    assign {carry_2, sum_2} = pp_1_1 + carry_1 + 1'b1; // Add 1 for two's complement
    assign p[2] = sum_2;
    
    // Fourth sum term (MSB)
    assign p[3] = carry_2;
endmodule