//SystemVerilog
module cdc_sync #(parameter WIDTH=1) (
    input src_clk, dst_clk, rst,
    input [WIDTH-1:0] async_in,
    output reg [WIDTH-1:0] sync_out
);
    reg [WIDTH-1:0] sync_reg1;
    reg [WIDTH-1:0] async_in_reg;
    
    // Register async_in directly at source clock domain
    always @(posedge src_clk or posedge rst) 
        async_in_reg <= rst ? {WIDTH{1'b0}} : async_in;

    // Two-stage synchronization in destination clock domain
    always @(posedge dst_clk or posedge rst) begin
        sync_reg1 <= rst ? {WIDTH{1'b0}} : async_in_reg;
        sync_out <= rst ? {WIDTH{1'b0}} : sync_reg1;
    end
endmodule