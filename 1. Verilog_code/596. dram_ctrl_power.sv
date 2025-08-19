module dram_ctrl_power #(
    parameter LOW_POWER_THRESH = 100
)(
    input clk,
    input activity,
    output reg clk_en
);
    reg [7:0] idle_counter;
    
    always @(posedge clk) begin
        if(activity) begin
            idle_counter <= 0;
            clk_en <= 1;
        end else if(idle_counter < LOW_POWER_THRESH) begin
            idle_counter <= idle_counter + 1;
            clk_en <= 1;
        end else begin
            clk_en <= 0; // 关闭时钟
        end
    end
endmodule
