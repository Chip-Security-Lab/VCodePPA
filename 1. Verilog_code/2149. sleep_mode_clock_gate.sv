module sleep_mode_clock_gate (
    input  wire sys_clk,
    input  wire sleep_req,
    input  wire wake_event,
    input  wire rst_n,
    output wire core_clk
);
    reg sleep_state;
    
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n)
            sleep_state <= 1'b0;
        else if (wake_event)
            sleep_state <= 1'b0;
        else if (sleep_req)
            sleep_state <= 1'b1;
    end
    
    assign core_clk = sys_clk & ~sleep_state;
endmodule