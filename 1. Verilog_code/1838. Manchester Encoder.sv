module manchester_encoder (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    input  wire polarity,   // 0=rising=1, 1=falling=0
    output reg  manchester_out
);
    reg clk_div2;
    
    // Clock divider by 2 for Manchester encoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div2 <= 1'b0;
        else
            clk_div2 <= ~clk_div2;
    end
    
    // Manchester encoding logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            manchester_out <= 1'b0;
        else
            manchester_out <= polarity ? (data_in ^ ~clk_div2) : (data_in ^ clk_div2);
    end
endmodule