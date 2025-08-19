//SystemVerilog
module latch_dff (
    input clk, en,
    input d,
    output reg q
);
    // Pipeline stage registers
    reg stage1_data;
    reg stage2_data;
    reg stage3_data;
    
    // Latch behavior on clock low phase
    always @(negedge clk) begin
        if (en) 
            stage1_data <= d;
    end
    
    // Combined positive edge triggered stages
    always @(posedge clk) begin
        stage2_data <= stage1_data;
        stage3_data <= stage2_data;
        q <= stage3_data;
    end
endmodule