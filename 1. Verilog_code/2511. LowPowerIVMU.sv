module LowPowerIVMU (
    input main_clk, rst_n,
    input [15:0] int_sources,
    input [15:0] int_mask,
    input clk_en,
    output reg [31:0] vector_out,
    output reg int_pending
);
    wire gated_clk;
    reg [31:0] vectors [0:15];
    wire [15:0] pending;
    integer i;
    
    assign gated_clk = main_clk & (clk_en | |pending);
    assign pending = int_sources & ~int_mask;
    
    initial for (i = 0; i < 16; i = i + 1)
        vectors[i] = 32'h9000_0000 + (i * 4);
    
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            vector_out <= 32'h0;
            int_pending <= 1'b0;
        end else begin
            int_pending <= |pending;
            if (|pending) begin
                for (i = 15; i >= 0; i = i - 1)
                    if (pending[i]) vector_out <= vectors[i];
            end
        end
    end
endmodule