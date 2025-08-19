module i2c_prog_timing_master #(
    parameter DEFAULT_PRESCALER = 16'd100
)(
    input clk, reset_n,
    input [15:0] scl_prescaler,
    input [7:0] tx_data,
    input [6:0] slave_addr,
    input start_tx,
    output reg tx_done,
    inout scl, sda
);
    reg [15:0] clk_div_count;
    reg [15:0] active_prescaler;
    reg scl_int, sda_int, scl_oe, sda_oe;
    reg [3:0] state;
    
    assign scl = scl_oe ? scl_int : 1'bz;
    assign sda = sda_oe ? sda_int : 1'bz;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            active_prescaler <= DEFAULT_PRESCALER;
        else if (state == 4'd0 && start_tx)
            active_prescaler <= (scl_prescaler == 16'd0) ? 
                              DEFAULT_PRESCALER : scl_prescaler;
    end
endmodule