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

    // Memory array
    reg [15:0] mode_regs [0:(1<<MR_ADDR_WIDTH)-1];
    
    // Parallel prefix subtractor signals
    wire [15:0] g [15:0];  // Generate
    wire [15:0] p [15:0];  // Propagate
    wire [15:0] c;         // Carry
    wire [15:0] diff;      // Difference
    
    // Mode register write logic
    always @(posedge clk) begin
        if(load_mr)
            mode_regs[mr_addr] <= mr_data;
    end
    
    // Parallel prefix subtractor implementation
    genvar i;
    generate
        // Initial propagate and generate
        for(i=0; i<16; i=i+1) begin: gen_pp
            assign p[i] = ~(mode_regs[mr_addr][i] ^ mr_data[i]);
            assign g[i] = mode_regs[mr_addr][i] & ~mr_data[i];
        end
        
        // Carry computation using parallel prefix
        assign c[0] = 1'b0;
        for(i=1; i<16; i=i+1) begin: gen_carry
            assign c[i] = g[i-1] | (p[i-1] & c[i-1]);
        end
        
        // Difference computation
        for(i=0; i<16; i=i+1) begin: gen_diff
            assign diff[i] = mode_regs[mr_addr][i] ^ mr_data[i] ^ c[i];
        end
    endgenerate
    
    // Output register
    always @(posedge clk) begin
        current_mode <= diff;
    end

endmodule