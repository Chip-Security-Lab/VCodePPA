module dram_mode_register #(
    parameter MR_ADDR_WIDTH = 4
)(
    input clk,
    input load_mr,
    input [MR_ADDR_WIDTH-1:0] mr_addr,
    input [15:0] mr_data,
    output reg [15:0] current_mode
);
    reg [15:0] mode_regs [0:(1<<MR_ADDR_WIDTH)-1];
    
    always @(posedge clk) begin
        if(load_mr)
            mode_regs[mr_addr] <= mr_data;
        
        current_mode <= mode_regs[mr_addr];
    end
endmodule
