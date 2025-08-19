//SystemVerilog
module PriorityLatch #(parameter N=4) (
    input clk, rst_n, en,
    input [N-1:0] req,
    output reg [N-1:0] grant,
    output reg valid
);

    // Single pipeline stage for better timing
    reg [N-1:0] req_reg;
    reg en_reg;
    
    // Priority encoding using leading zero detection
    wire [N-1:0] mask;
    wire [N-1:0] grant_next;
    
    // Generate mask for priority encoding
    assign mask = req_reg & (~req_reg + 1);
    
    // Next state logic
    assign grant_next = en_reg ? mask : {N{1'b0}};
    
    // Single pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_reg <= {N{1'b0}};
            en_reg <= 1'b0;
            grant <= {N{1'b0}};
            valid <= 1'b0;
        end else begin
            req_reg <= req;
            en_reg <= en;
            grant <= grant_next;
            valid <= en_reg;
        end
    end

endmodule