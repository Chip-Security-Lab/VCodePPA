module multi_phase_clk_gen(
    input clk_in,
    input reset,
    output reg clk_0,    // 0 degrees
    output reg clk_90,   // 90 degrees
    output reg clk_180,  // 180 degrees
    output reg clk_270   // 270 degrees
);
    reg [1:0] count;
    
    always @(posedge clk_in or posedge reset) begin
        if (reset)
            count <= 2'b00;
        else
            count <= count + 2'b01;
    end
    
    always @(*) begin
        clk_0   = (count == 2'b00);
        clk_90  = (count == 2'b01);
        clk_180 = (count == 2'b10);
        clk_270 = (count == 2'b11);
    end
endmodule