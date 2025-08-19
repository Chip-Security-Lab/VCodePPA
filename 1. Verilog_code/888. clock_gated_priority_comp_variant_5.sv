//SystemVerilog
module clock_gated_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n, enable,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out
);
    // Clock gating cell (simplified for synthesis)
    wire gated_clk;
    reg enable_latch;
    
    always @(clk or enable)
        if (!clk) enable_latch <= enable;
        
    assign gated_clk = clk & enable_latch;
    
    // Priority logic with borrow subtractor
    reg [WIDTH-1:0] borrow;
    reg [$clog2(WIDTH)-1:0] temp_priority;
    
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
            borrow <= 0;
            temp_priority <= 0;
        end else begin
            borrow <= 0;
            temp_priority <= 0;
            
            for (integer i = WIDTH-1; i >= 0; i = i - 1) begin
                if (data_in[i] && !borrow[i]) begin
                    temp_priority <= i[$clog2(WIDTH)-1:0];
                    borrow[i] <= 1'b1;
                end
            end
            
            priority_out <= temp_priority;
        end
    end
endmodule