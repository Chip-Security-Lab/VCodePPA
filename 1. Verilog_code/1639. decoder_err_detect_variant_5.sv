//SystemVerilog
module decoder_err_detect #(MAX_ADDR=16'hFFFF) (
    input wire clk,
    input wire rst_n,
    input wire [15:0] addr,
    output reg select,
    output reg err
);

    // Single pipeline stage with optimized comparison
    reg [15:0] addr_reg;
    
    // Optimized comparison logic
    wire addr_in_range;
    wire addr_out_of_range;
    
    // Efficient range check implementation
    assign addr_in_range = (addr_reg < MAX_ADDR);
    assign addr_out_of_range = ~addr_in_range;
    
    // Single pipeline stage with optimized logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= 16'h0;
            select <= 1'b0;
            err <= 1'b0;
        end else begin
            addr_reg <= addr;
            select <= addr_in_range;
            err <= addr_out_of_range;
        end
    end

endmodule