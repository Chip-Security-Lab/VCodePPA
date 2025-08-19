//SystemVerilog
module dram_mode_register #(
    parameter MR_ADDR_WIDTH = 4
)(
    input clk,
    input load_mr,
    input [MR_ADDR_WIDTH-1:0] mr_addr,
    input [15:0] mr_data,
    output reg [15:0] current_mode
);

    // Mode registers
    reg [15:0] mode_regs [0:(1<<MR_ADDR_WIDTH)-1];
    
    // Manchester carry chain adder signals
    wire [15:0] g, p;
    wire [15:0] carry;
    wire [15:0] sum;
    
    // Generate and propagate signals
    genvar i;
    generate
        for(i = 0; i < 16; i = i + 1) begin : gen_prop
            assign g[i] = (mr_addr == i) ? mode_regs[i][15] : 1'b0;
            assign p[i] = (mr_addr == i) ? mode_regs[i][14:0] : 15'b0;
        end
    endgenerate
    
    // Manchester carry chain
    assign carry[0] = 1'b0;
    genvar j;
    generate
        for(j = 0; j < 15; j = j + 1) begin : carry_chain
            assign carry[j+1] = g[j] | (p[j] & carry[j]);
        end
    endgenerate
    
    // Final sum
    assign sum = {g[15], p[14:0]} ^ {carry[14:0], 1'b0};
    
    always @(posedge clk) begin
        if(load_mr)
            mode_regs[mr_addr] <= mr_data;
        
        current_mode <= sum;
    end

endmodule